"""
Simple Document Service
A REST API service for storing and retrieving documents with caching.
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import logging
import os
from functools import lru_cache
from typing import Optional
import boto3
import redis
from datetime import datetime

from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError
from redis.exceptions import RedisError
import time

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='{"timestamp": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s", "module": "%(name)s"}'
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Document Service", version="1.0.0")

@app.on_event("startup")
async def _startup_connectivity_log() -> None:
    """Initialize external clients and log connectivity at startup."""
    storage = _check_storage_ready()
    cache = _check_cache_ready()

    logger.info(
        "Startup dependency check checks=%s",
        {"storage": storage, "cache": cache},
    )

# Configuration
MAX_CONTENT_SIZE = 100 * 1024  # 100 KB
STORAGE_BUCKET = os.getenv('STORAGE_BUCKET', 'document-service-storage')
STORAGE_TYPE = os.getenv('STORAGE_TYPE', 's3')  # 's3', 'dynamodb', 'rds'

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
S3_ENDPOINT_URL = os.getenv("S3_ENDPOINT_URL")  # Optional (e.g., LocalStack/MinIO)
S3_KEY_PREFIX = os.getenv("S3_KEY_PREFIX", "documents").strip("/")

S3_SSE = os.getenv("S3_SSE", "AES256")  # AES256 | aws:kms | (empty/none)
S3_KMS_KEY_ID = os.getenv("S3_KMS_KEY_ID")
S3_CONNECT_TIMEOUT_SECONDS = float(os.getenv("S3_CONNECT_TIMEOUT_SECONDS", "2"))
S3_READ_TIMEOUT_SECONDS = float(os.getenv("S3_READ_TIMEOUT_SECONDS", "5"))
S3_MAX_ATTEMPTS = int(os.getenv("S3_MAX_ATTEMPTS", "5"))

CACHE_HOST = os.getenv("CACHE_HOST")
CACHE_PORT = int(os.getenv("CACHE_PORT", "6379"))
CACHE_DB = int(os.getenv("CACHE_DB", "0"))
CACHE_SSL = os.getenv("CACHE_SSL", "false").lower() in {"1", "true", "yes"}
CACHE_USERNAME = os.getenv("CACHE_USERNAME")
CACHE_PASSWORD = os.getenv("CACHE_PASSWORD")
CACHE_CONNECT_TIMEOUT_SECONDS = float(os.getenv("CACHE_CONNECT_TIMEOUT_SECONDS", "1"))
CACHE_SOCKET_TIMEOUT_SECONDS = float(os.getenv("CACHE_SOCKET_TIMEOUT_SECONDS", "1"))
CACHE_TTL_SECONDS = int(os.getenv("CACHE_TTL_SECONDS", "3600"))


class DocumentRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=MAX_CONTENT_SIZE, description="Document content")


class DocumentResponse(BaseModel):
    id: str
    content: str
    created_at: Optional[str] = None


def _s3_key_for_document(document_id: str) -> str:
    prefix = S3_KEY_PREFIX
    if prefix:
        return f"{prefix}/{document_id}"
    return document_id


@lru_cache(maxsize=1)
def _get_s3_client():
    config = Config(
        retries={"max_attempts": S3_MAX_ATTEMPTS, "mode": "standard"},
        connect_timeout=S3_CONNECT_TIMEOUT_SECONDS,
        read_timeout=S3_READ_TIMEOUT_SECONDS,
    )
    return boto3.client(
        "s3",
        region_name=AWS_REGION,
        endpoint_url=S3_ENDPOINT_URL or None,
        config=config,
    )


@lru_cache(maxsize=1)
def _get_cache_client() -> Optional[redis.Redis]:
    if not CACHE_HOST:
        return None

    client = redis.Redis(
        host=CACHE_HOST,
        port=CACHE_PORT,
        db=CACHE_DB,
        username=CACHE_USERNAME,
        password=CACHE_PASSWORD,
        ssl=CACHE_SSL,
        socket_connect_timeout=CACHE_CONNECT_TIMEOUT_SECONDS,
        socket_timeout=CACHE_SOCKET_TIMEOUT_SECONDS,
        decode_responses=True,
        health_check_interval=30,
    )

    # Don't ping here: readiness will validate connectivity, and runtime cache ops
    # already degrade gracefully if Redis is temporarily unavailable.
    return client


def _check_storage_ready() -> dict:
    if STORAGE_TYPE != "s3":
        return {
            "status": "fail",
            "type": STORAGE_TYPE,
            "detail": "unsupported storage type",
        }

    started = time.perf_counter()
    try:
        _get_s3_client().head_bucket(Bucket=STORAGE_BUCKET)
        latency_ms = int((time.perf_counter() - started) * 1000)
        return {
            "status": "ok",
            "type": "s3",
            "bucket": STORAGE_BUCKET,
            "latency_ms": latency_ms,
        }
    except (ClientError, BotoCoreError) as e:
        latency_ms = int((time.perf_counter() - started) * 1000)
        return {
            "status": "fail",
            "type": "s3",
            "bucket": STORAGE_BUCKET,
            "latency_ms": latency_ms,
            "error": str(e),
        }


def _check_cache_ready() -> dict:
    if not CACHE_HOST:
        return {"status": "skipped", "detail": "CACHE_HOST not set"}

    client = _get_cache_client()
    if client is None:
        return {"status": "fail", "detail": "cache client not configured"}

    started = time.perf_counter()
    try:
        client.ping()
        latency_ms = int((time.perf_counter() - started) * 1000)
        return {
            "status": "ok",
            "type": "redis",
            "host": CACHE_HOST,
            "port": CACHE_PORT,
            "latency_ms": latency_ms,
        }
    except RedisError as e:
        latency_ms = int((time.perf_counter() - started) * 1000)
        return {
            "status": "fail",
            "type": "redis",
            "host": CACHE_HOST,
            "port": CACHE_PORT,
            "latency_ms": latency_ms,
            "error": str(e),
        }


def store_document(document_id: str, content: str) -> bool:
    """
    Store document in durable storage.
    TODO: Implement based on your storage choice (S3, DynamoDB, RDS).
    
    Returns True if successful, False otherwise.
    """
    if STORAGE_TYPE != "s3":
        logger.error(f"Unsupported STORAGE_TYPE={STORAGE_TYPE} (expected 's3')")
        return False

    key = _s3_key_for_document(document_id)
    created_at = datetime.utcnow().isoformat() + "Z"

    try:
        put_kwargs = {
            "Bucket": STORAGE_BUCKET,
            "Key": key,
            "Body": content.encode("utf-8"),
            "ContentType": "text/plain; charset=utf-8",
            "Metadata": {
                "document-id": document_id,
                "created-at": created_at,
            },
        }

        sse = (S3_SSE or "").strip()
        if sse and sse.lower() != "none":
            put_kwargs["ServerSideEncryption"] = sse
            if sse == "aws:kms" and S3_KMS_KEY_ID:
                put_kwargs["SSEKMSKeyId"] = S3_KMS_KEY_ID

        _get_s3_client().put_object(**put_kwargs)

        logger.info(f"Stored document {document_id} in S3 bucket {STORAGE_BUCKET}")
        return True
    except (ClientError, BotoCoreError) as e:
        logger.error(f"Error storing document {document_id} to S3: {str(e)}", exc_info=True)
        return False
    except Exception as e:
        logger.error(f"Unexpected error storing document {document_id}: {str(e)}", exc_info=True)
        return False


def retrieve_document(document_id: str) -> Optional[str]:
    """
    Retrieve document from durable storage.
    TODO: Implement based on your storage choice.
    
    Returns document content or None if not found.
    """
    if STORAGE_TYPE != "s3":
        logger.error(f"Unsupported STORAGE_TYPE={STORAGE_TYPE} (expected 's3')")
        return None

    key = _s3_key_for_document(document_id)

    try:
        response = _get_s3_client().get_object(Bucket=STORAGE_BUCKET, Key=key)
        body = response["Body"].read()
        return body.decode("utf-8")
    except ClientError as e:
        code = (e.response or {}).get("Error", {}).get("Code", "")
        if code in {"NoSuchKey", "404", "NotFound"}:
            return None
        logger.error(f"S3 error retrieving document {document_id}: {str(e)}", exc_info=True)
        return None
    except (BotoCoreError, Exception) as e:
        logger.error(f"Error retrieving document {document_id}: {str(e)}", exc_info=True)
        return None


def get_from_cache(document_id: str) -> Optional[str]:
    """
    Get document from cache.
    TODO: Implement cache retrieval.
    """
    client = _get_cache_client()
    if client is None:
        return None

    cache_key = f"document:{document_id}"
    try:
        cached = client.get(cache_key)
        if cached is None:
            logger.info(f"Cache miss for document {document_id}")
            return None
        logger.info(f"Cache hit for document {document_id}")
        return cached
    except RedisError as e:
        logger.warning(f"Cache error for document {document_id}: {str(e)}")
        return None  # Graceful degradation - fallback to storage


def set_in_cache(document_id: str, content: str, ttl: int = 3600) -> bool:
    """
    Store document in cache.
    TODO: Implement cache storage.
    """
    client = _get_cache_client()
    if client is None:
        return False

    cache_key = f"document:{document_id}"
    effective_ttl = ttl or CACHE_TTL_SECONDS

    try:
        client.setex(cache_key, effective_ttl, content)
        return True
    except RedisError as e:
        logger.warning(f"Cache error storing document {document_id}: {str(e)}")
        return False  # Non-fatal - cache is optional


def invalidate_cache(document_id: str) -> None:
    """
    Invalidate cache entry for document.
    TODO: Implement cache invalidation.
    """
    client = _get_cache_client()
    if client is None:
        return

    cache_key = f"document:{document_id}"
    try:
        client.delete(cache_key)
    except RedisError as e:
        logger.warning(f"Cache invalidation error for document {document_id}: {str(e)}")


@app.get("/health/live")
async def health_live():
    """Liveness probe: answers if the process is running."""
    return {
        "status": "ok",
        "service": "document-service",
        "version": app.version,
        "time": datetime.utcnow().isoformat() + "Z",
    }


@app.get("/health/ready")
async def health_ready():
    """Readiness probe: answers if the service can handle traffic."""
    storage = _check_storage_ready()
    cache = _check_cache_ready()

    # Storage is required; cache is optional (degrade gracefully).
    ready = storage.get("status") == "ok"
    overall = "ok" if ready else "fail"
    if ready and cache.get("status") == "fail":
        overall = "degraded"

    payload = {
        "status": overall,
        "service": "document-service",
        "version": app.version,
        "time": datetime.utcnow().isoformat() + "Z",
        "checks": {
            "storage": storage,
            "cache": cache,
        },
    }

    if not ready:
        raise HTTPException(status_code=503, detail=payload)

    return payload


@app.get("/health")
async def health_check():
    """Backwards-compatible alias for readiness."""
    return await health_ready()


@app.put("/documents/{document_id}")
async def put_document(document_id: str, request: DocumentRequest):
    """
    Store a document.
    """
    try:
        logger.info(f"Storing document {document_id}, size: {len(request.content)} bytes")
        
        # Validate content size
        if len(request.content) > MAX_CONTENT_SIZE:
            raise HTTPException(
                status_code=400,
                detail=f"Content exceeds maximum size of {MAX_CONTENT_SIZE} bytes"
            )
        
        # Store in durable storage
        if not store_document(document_id, request.content):
            raise HTTPException(
                status_code=500,
                detail="Failed to store document in durable storage"
            )
        
        # Invalidate cache (write-through or cache-aside pattern)
        invalidate_cache(document_id)
        
        # Optionally: Update cache (write-through pattern)
        # set_in_cache(document_id, request.content)
        
        logger.info(f"Successfully stored document {document_id}")
        
        return {
            "id": document_id,
            "status": "stored",
            "size": len(request.content)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error storing document {document_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


@app.get("/documents/{document_id}", response_model=DocumentResponse)
async def get_document(document_id: str):
    """
    Retrieve a document.
    Implements cache-aside pattern: check cache first, then storage.
    """
    try:
        logger.info(f"Retrieving document {document_id}")
        
        # Try cache first (cache-aside pattern)
        cached_content = get_from_cache(document_id)
        if cached_content:
            logger.info(f"Cache hit for document {document_id}")
            return DocumentResponse(
                id=document_id,
                content=cached_content,
                created_at=datetime.utcnow().isoformat()
            )
        
        # Cache miss - retrieve from storage
        logger.info(f"Cache miss for document {document_id}, fetching from storage")
        content = retrieve_document(document_id)
        
        if content is None:
            raise HTTPException(status_code=404, detail=f"Document {document_id} not found")
        
        # Populate cache for future reads (cache-aside pattern)
        set_in_cache(document_id, content)
        
        logger.info(f"Successfully retrieved document {document_id}")
        
        return DocumentResponse(
            id=document_id,
            content=content,
            created_at=datetime.utcnow().isoformat()
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving document {document_id}: {str(e)}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)
