# Data sources to reference shared and VPC infrastructure
# Refactored to use AWS data sources instead of terraform_remote_state
# This eliminates dependency on state files and provides better decoupling

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

# Get ALB by tag
data "aws_lb" "main" {
  name = "${var.project_name}-alb"
}

# Get target group by name
data "aws_lb_target_group" "app" {
  name = "${var.project_name}-tg"
}

# Get EKS cluster by name
data "aws_eks_cluster" "main" {
  name = "${var.project_name}-eks-cluster"
}

# Get ElastiCache security group by tag
data "aws_security_group" "elasticache" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-elasticache-sg"]
  }

  vpc_id = data.aws_vpc.main.id
}

# Local references to infrastructure resources
locals {
  vpc_id              = data.aws_vpc.main.id
  private_subnet_1_id = data.aws_subnet.private_1.id
  private_subnet_2_id = data.aws_subnet.private_2.id
  alb_arn_suffix      = data.aws_lb.main.arn_suffix
  target_group_arn_suffix = data.aws_lb_target_group.app.arn_suffix
  eks_cluster_name    = data.aws_eks_cluster.main.name
  elasticache_security_group_id = data.aws_security_group.elasticache.id
}
