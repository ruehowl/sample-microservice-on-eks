# Data sources to reference VPC infrastructure
# Refactored to use AWS data sources instead of terraform_remote_state
# This eliminates dependency on state files and provides better decoupling

# Get VPC by tag
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-vpc"]
  }
}

# Get public subnets by VPC and tag
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Type"
    values = ["Public"]
  }
}

# Get public subnet 1 (first AZ)
data "aws_subnet" "public_1" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-public-subnet-1"]
  }
}

# Get public subnet 2 (second AZ)
data "aws_subnet" "public_2" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-public-subnet-2"]
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

# Local references to VPC resources
locals {
  vpc_id              = data.aws_vpc.main.id
  public_subnet_1_id  = data.aws_subnet.public_1.id
  public_subnet_2_id  = data.aws_subnet.public_2.id
  private_subnet_1_id = data.aws_subnet.private_1.id
  private_subnet_2_id = data.aws_subnet.private_2.id
  private_subnet_1_cidr = data.aws_subnet.private_1.cidr_block
  private_subnet_2_cidr = data.aws_subnet.private_2.cidr_block
}
