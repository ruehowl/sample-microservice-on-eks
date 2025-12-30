# Main Terraform Configuration - Refactored into Modular Files
#
# This directory follows Terraform best practices with configuration split into logical files:
#
# - provider.tf: Terraform version, required providers, and AWS provider configuration
# - vpc.tf: VPC, subnets, route tables, NAT gateway, and networking resources
# - ecr.tf: Elastic Container Registry repository and lifecycle policies
# - security_groups.tf: Security groups for ALB, application, and ElastiCache
# - alb.tf: Application Load Balancer, target groups, and listeners
# - iam.tf: All IAM roles and policies including IRSA (IAM Roles for Service Accounts)
# - eks.tf: EKS cluster, node groups, and managed add-ons
# - storage.tf: DynamoDB table for document storage
# - cache.tf: ElastiCache Redis cluster and configuration
# - monitoring.tf: CloudWatch log groups, dashboards, alarms, and metric filters
# - variables.tf: Input variables with descriptions and defaults
# - outputs.tf: Output values for cross-stack references
#
# This structure provides:
# ✓ Clear separation of concerns
# ✓ Easier maintenance and navigation
# ✓ Better code reusability and testing
# ✓ Simplified collaboration on specific infrastructure components
#
# All configuration has been modularized into the separate files listed above.
# This file is intentionally kept minimal for documentation purposes.
