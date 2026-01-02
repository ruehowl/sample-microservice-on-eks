# Data sources to reference shared and VPC infrastructure
# Refactored to use AWS data sources instead of terraform_remote_state
# This eliminates dependency on state files and provides better decoupling

# Get current AWS account ID (used for building ARNs)
data "aws_caller_identity" "current" {}

# Get VPC by tag
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-vpc"]
  }
}

# Get private subnets by VPC and tag
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Type"
    values = ["Private"]
  }
}

# Get private subnet 1 (first AZ)
data "aws_subnet" "private_1" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-private-subnet-1"]
  }
}

# Get private subnet 2 (second AZ)
data "aws_subnet" "private_2" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-private-subnet-2"]
  }
}

# Get EKS cluster by name
data "aws_eks_cluster" "main" {
  name = "${var.project_name}-eks-cluster"
}

# Local references to infrastructure resources
locals {
  vpc_id                        = data.aws_vpc.main.id
  private_subnet_1_id           = data.aws_subnet.private_1.id
  private_subnet_2_id           = data.aws_subnet.private_2.id
  eks_cluster_name              = data.aws_eks_cluster.main.name
  elasticache_security_group_id = aws_security_group.elasticache.id

  oidc_provider_hostpath = replace(data.aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
  oidc_provider_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider_hostpath}"
}

