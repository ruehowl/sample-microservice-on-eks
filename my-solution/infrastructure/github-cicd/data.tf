# Data sources to reference EKS infrastructure
# Refactored to use AWS data sources instead of terraform_remote_state
# This eliminates dependency on state files and provides better decoupling

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get EKS cluster by name
data "aws_eks_cluster" "main" {
  name = "${var.project_name}-eks-cluster"
}

# Get IAM role for app service account by name
data "aws_iam_role" "app_service_account" {
  name = "${var.project_name}-app-sa-role"
}

# Local references to infrastructure resources
locals {
  app_service_account_arn = data.aws_iam_role.app_service_account.arn
  ecr_repository_arn      = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/*"
  eks_cluster_arn         = data.aws_eks_cluster.main.arn
}
