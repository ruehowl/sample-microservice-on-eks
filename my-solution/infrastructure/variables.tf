# Variable definitions for Terraform configuration

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

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet (for ALB and NAT Gateway)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet (for application, cache, and storage)"
  type        = string
  default     = "10.0.2.0/24"
}

# EKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_instance_types" {
  description = "Instance types for EKS worker nodes (using t3.medium for cost savings)"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "use_spot_instances" {
  description = "Use Spot Instances for EKS nodes (saves ~70% on compute costs)"
  type        = bool
  default     = true
}

# ALB Configuration
variable "alb_port" {
  description = "Port for ALB listener"
  type        = number
  default     = 80
}

variable "app_port" {
  description = "Port for application container"
  type        = number
  default     = 8000
}

# Storage Configuration
variable "storage_type" {
  description = "Type of storage to use: 'dynamodb' or 's3'"
  type        = string
  default     = "dynamodb"
}

# Cache Configuration
variable "elasticache_node_type" {
  description = "Node type for ElastiCache Redis (cache.t3.micro for cost savings)"
  type        = string
  default     = "cache.t3.micro"
}

