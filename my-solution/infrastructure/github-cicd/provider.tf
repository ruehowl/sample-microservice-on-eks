terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Configure S3 backend for state
  backend "s3" {
    bucket         = "rahul-varghese-sleek-task-terraform-state-bucket"
    key            = "sre-assessment/github-cicd/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "principal-sre-assessment"
      Environment = var.environment
      ManagedBy   = "Terraform"
      # IMPORTANT: Candidate tag is required for cost tracking
      # The budget only tracks costs for resources tagged with your candidate name
      Candidate = var.candidate_name
    }
  }
}
