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

# Get ECR repository by name
data "aws_ecr_repository" "app" {
  name = "${var.project_name}-${var.candidate_name}"
}

# Local references to infrastructure resources
locals {
  app_service_account_arn = data.aws_iam_role.app_service_account.arn
  ecr_repository_arn      = data.aws_ecr_repository.app.arn
  eks_cluster_arn         = data.aws_eks_cluster.main.arn
}
