# DynamoDB Table for Document Storage
# Chosen for: scalable, serverless, high performance for key-value access
resource "aws_dynamodb_table" "documents" {
  name           = "${var.project_name}-documents"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand pricing for cost efficiency
  hash_key       = "document_id"

  attribute {
    name = "document_id"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-documents-table"
  }
}
