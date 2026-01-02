# Data sources to reference EKS infrastructure
# Refactored to use AWS data sources instead of terraform_remote_state
# This eliminates dependency on state files and provides better decoupling

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Local references to infrastructure resources
locals {
  ecr_repository_arn = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/*"
}
