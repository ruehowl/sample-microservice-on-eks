# EKS Module Outputs

# EKS Cluster Outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

# IAM Role Outputs
output "eks_cluster_role_arn" {
  description = "IAM role ARN for the EKS cluster"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS nodes"
  value       = aws_iam_role.eks_node_role.arn
}

# OIDC Provider Outputs
output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "eks_oidc_provider_url" {
  description = "URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.cluster.url
}

output "alb_controller_role_arn" {
  description = "IAM role ARN assumed by the aws-load-balancer-controller service account (IRSA)"
  value       = module.aws_load_balancer_controller_irsa.iam_role_arn
}

output "vpc_id" {
  description = "VPC ID where the EKS cluster runs"
  value       = local.vpc_id
}
