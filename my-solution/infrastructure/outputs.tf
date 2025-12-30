# Output values for Terraform configuration

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Outputs
output "public_subnet_id" {
  description = "ID of the public subnet 1"
  value       = aws_subnet.public_1.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet 1"
  value       = aws_subnet.public_1.cidr_block
}

output "private_subnet_id" {
  description = "ID of the private subnet 1"
  value       = aws_subnet.private_1.id
}

output "private_subnet_cidr" {
  description = "CIDR block of the private subnet 1"
  value       = aws_subnet.private_1.cidr_block
}

# Internet Gateway Outputs
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# NAT Gateway Outputs
output "nat_gateway_id" {
  description = "ID of the NAT Gateway 1"
  value       = aws_nat_gateway.main_1.id
}

output "nat_gateway_eip" {
  description = "Elastic IP address of the NAT Gateway 1"
  value       = aws_eip.nat_1.public_ip
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table 1"
  value       = aws_route_table.private_1.id
}

# ECR Repository Outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.app.name
}

# EKS Cluster Outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "eks_cluster_security_group_id" {
  description = "Security group ID of the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "eks_cluster_iam_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_group_id" {
  description = "ID of the EKS node group"
  value       = aws_eks_node_group.main.id
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS nodes"
  value       = aws_iam_role.eks_node_role.arn
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "eks_oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.cluster.url
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID for the application"
  value       = aws_security_group.app.id
}

# Application Service Account IAM Role Outputs
output "app_service_account_role_arn" {
  description = "ARN of the application service account role (for IRSA)"
  value       = aws_iam_role.app_service_account.arn
}

output "app_service_account_role_name" {
  description = "Name of the application service account role"
  value       = aws_iam_role.app_service_account.name
}

# CI/CD IAM Role Outputs
output "cicd_role_arn" {
  description = "ARN of the CI/CD pipeline role"
  value       = aws_iam_role.cicd_role.arn
}

output "cicd_role_name" {
  description = "Name of the CI/CD pipeline role"
  value       = aws_iam_role.cicd_role.name
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "terraform_cicd_role_arn" {
  description = "ARN of the Terraform CI/CD IAM role for GitHub Actions"
  value       = aws_iam_role.terraform_cicd_role.arn
}

output "terraform_cicd_role_name" {
  description = "Name of the Terraform CI/CD IAM role"
  value       = aws_iam_role.terraform_cicd_role.name
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

# CloudWatch Log Group Outputs
output "eks_cluster_log_group_name" {
  description = "Name of the EKS cluster log group"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "app_log_group_name" {
  description = "Name of the application log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "alb_log_group_name" {
  description = "Name of the ALB log group"
  value       = aws_cloudwatch_log_group.alb.name
}

# CloudWatch Dashboard Output
output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

# CloudWatch Alarm Outputs
output "alb_response_time_alarm_name" {
  description = "Name of the ALB response time alarm"
  value       = aws_cloudwatch_metric_alarm.alb_response_time.alarm_name
}

output "alb_5xx_errors_alarm_name" {
  description = "Name of the ALB 5xx errors alarm"
  value       = aws_cloudwatch_metric_alarm.alb_5xx_errors.alarm_name
}

output "app_errors_alarm_name" {
  description = "Name of the application errors alarm"
  value       = aws_cloudwatch_metric_alarm.app_errors.alarm_name
}

# DynamoDB Outputs
output "dynamodb_table_name" {
  description = "Name of the DynamoDB documents table"
  value       = aws_dynamodb_table.documents.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB documents table"
  value       = aws_dynamodb_table.documents.arn
}

# ElastiCache Outputs
output "elasticache_cluster_id" {
  description = "ID of the ElastiCache Redis cluster"
  value       = aws_elasticache_cluster.main.cluster_id
}

output "elasticache_cluster_endpoint" {
  description = "Endpoint of the ElastiCache Redis cluster"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "elasticache_cluster_port" {
  description = "Port of the ElastiCache Redis cluster"
  value       = aws_elasticache_cluster.main.cache_nodes[0].port
}

output "elasticache_security_group_id" {
  description = "Security group ID for ElastiCache"
  value       = aws_security_group.elasticache.id
}

# EKS Add-ons Outputs
output "eks_addon_vpc_cni_version" {
  description = "Version of VPC CNI add-on"
  value       = aws_eks_addon.vpc_cni.addon_version
}

output "eks_addon_coredns_version" {
  description = "Version of CoreDNS add-on"
  value       = aws_eks_addon.coredns.addon_version
}

output "eks_addon_kube_proxy_version" {
  description = "Version of kube-proxy add-on"
  value       = aws_eks_addon.kube_proxy.addon_version
}

# AWS Load Balancer Controller IAM Role Output
output "alb_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller role"
  value       = aws_iam_role.alb_controller_role.arn
}

# VPC CNI Role Output
output "eks_vpc_cni_role_arn" {
  description = "ARN of the EKS VPC CNI role"
  value       = aws_iam_role.eks_vpc_cni_role.arn
}

# TODO: Define outputs for important resources
# Examples:

# output "alb_dns_name" {
#   description = "DNS name of the Application Load Balancer"
#   value       = aws_lb.main.dns_name
# }

# output "ecr_repository_url" {
#   description = "URL of the ECR repository"
#   value       = aws_ecr_repository.app.repository_url
# }

# output "eks_cluster_endpoint" {
#   description = "Endpoint for EKS control plane"
#   value       = aws_eks_cluster.main.endpoint
# }

# output "ecs_cluster_name" {
#   description = "Name of the ECS cluster"
#   value       = aws_ecs_cluster.main.name
# }

# output "cloudwatch_log_group" {
#   description = "CloudWatch log group name"
#   value       = aws_cloudwatch_log_group.app.name
# }

