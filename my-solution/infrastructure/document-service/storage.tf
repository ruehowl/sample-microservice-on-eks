# S3 Bucket for Document Storage
resource "aws_s3_bucket" "document_storage" {
  bucket = "${var.candidate_name}-${var.project_name}-${var.environment}-storage"

  tags = {
    Name = "${var.project_name}-storage"
  }
}

resource "aws_s3_bucket_public_access_block" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "document_storage" {
  bucket = aws_s3_bucket.document_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
