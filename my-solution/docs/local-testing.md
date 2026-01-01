# Local Testing with Docker Compose

This guide explains how to spin up the document service locally using `docker-compose`, interact with it, and validate the cache + storage integrations mocked in the starter code.

## Prerequisites
- Docker Desktop (v4.x or newer) with Compose v2 enabled.
- Network access to pull Docker Hub images.
- Optional: `curl` or `httpie` for making HTTP requests; `redis-cli` for debugging Redis cache entries.

## 1. Start the Stack
```sh
cd my-solution/app
docker compose up --build
```

Key notes:
- `--build` ensures the `app` image is rebuilt after code changes.
- The compose file publishes API port `8000` and Redis port `6379` to localhost.
- Logs from both containers stream in the terminal. Use `Ctrl+C` to stop the stack.

To run in detached mode:
```sh
docker compose up --build -d
```
Stop and clean up containers/volumes when finished:
```sh
docker compose down -v
```

## 2. Verify Health
Once containers report healthy, confirm the service responds:
```sh
curl -s http://localhost:8000/health | jq
```
You should see JSON detailing overall status and component checks. If you do not have `jq`, omit the pipe.

## 3. Exercise API Endpoints
### Create or Update a Document
```sh
curl -X PUT "http://localhost:8000/documents/example-id" \
  -H "Content-Type: application/json" \
  -d '{"content": "hello from docker-compose"}'
```
Expected response:
```json
{
  "id": "example-id",
  "status": "stored",
  "size": 27
}
```

### Retrieve a Document
```sh
curl http://localhost:8000/documents/example-id
```
Look for the document content in the payload. Repeat the request to validate cache hit behavior (log lines should indicate cache usage).

### Attempt to Fetch a Missing Document
```sh
curl -i http://localhost:8000/documents/missing-id
```
Expect an `HTTP/1.1 404 Not Found` response, confirming error handling works.

## 4. Observe Logs and Cache
- The FastAPI container emits structured JSON logs to stdout; look for cache hit/miss information when invoking endpoints.
- Inspect Redis keys (requires `redis-cli` inside the container):
  ```sh
  docker compose exec redis redis-cli keys "document:*"
  ```
  Use `get` to inspect values:
  ```sh
  docker compose exec redis redis-cli get "document:example-id"
  ```

## 5. Configure Environment Variables
Adjust default values in `my-solution/app/docker-compose.yml` under the `app` service:
- `STORAGE_TYPE`: Choose `s3`, `dynamodb`, or `rds` as implementations become available.
- `STORAGE_BUCKET`: Set to the S3 bucket name when integrating with real AWS resources.
- `CACHE_HOST`, `CACHE_PORT`: Update if you run Redis elsewhere.

Changes require restarting the stack to take effect. Use `docker compose down` followed by `docker compose up --build`.

## 6. Running Tests Inside the Container (Optional)
Enter the `app` container shell:
```sh
docker compose exec app /bin/sh
```
From there you can run `pytest`, `ruff`, or other tooling once added to the image. Exit with `Ctrl+D` when done.

## 7. Troubleshooting
- If the health check fails, review container logs: `docker compose logs app` and `docker compose logs redis`.
- Port conflicts on `8000` or `6379` require adjusting published ports in the compose file.
- Rebuild the container after modifying Python dependencies to ensure they are included: `docker compose build app`.

Following these steps ensures you can iterate on the document service quickly with a fully containerized local environment.


