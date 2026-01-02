# Variable definitions for Terraform configuration used by the document-service stack

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "document-service"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "candidate_name" {
  description = "Candidate name for resource tagging (required for cost tracking). Extract from repository name: principal-sre-assessment-<candidate-name>"
  type        = string
  default     = "rahul-varghese"
}

# Cache Configuration
variable "elasticache_node_type" {
  description = "Node type for ElastiCache Redis (cache.t3.micro for cost savings)"
  type        = string
  default     = "cache.t3.micro"
}


