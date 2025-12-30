# ===== EKS CLUSTER =====

resource "aws_eks_cluster" "main" {
  name            = "${var.project_name}-eks-cluster"
  role_arn        = aws_iam_role.eks_cluster_role.arn
  version         = var.kubernetes_version
  
  vpc_config {
    subnet_ids              = [aws_subnet.public_1.id, aws_subnet.public_2.id, aws_subnet.private_1.id, aws_subnet.private_2.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Enable control plane logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # Ensure IAM role is created before cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]

  tags = {
    Name = "${var.project_name}-eks-cluster"
  }
}

# ===== EKS NODE GROUP =====

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  version         = var.kubernetes_version

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  instance_types = var.node_instance_types

  # Use Spot Instances for cost savings (~70% cheaper)
  capacity_type = var.use_spot_instances ? "SPOT" : "ON_DEMAND"

  # EBS volume size for nodes (in GB)
  disk_size = 20

  tags = {
    Name = "${var.project_name}-node-group"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_iam_role_policy_attachment.eks_ecr_full_access,
  ]
}

# ===== EKS MANAGED ADD-ONS =====

# Get latest addon versions
data "aws_eks_addon_version" "vpc_cni" {
  addon_name             = "vpc-cni"
  kubernetes_version     = aws_eks_cluster.main.version
  most_recent            = true
}

data "aws_eks_addon_version" "coredns" {
  addon_name             = "coredns"
  kubernetes_version     = aws_eks_cluster.main.version
  most_recent            = true
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name             = "kube-proxy"
  kubernetes_version     = aws_eks_cluster.main.version
  most_recent            = true
}

# VPC CNI Add-on for pod networking
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  addon_version            = data.aws_eks_addon_version.vpc_cni.version
  service_account_role_arn = aws_iam_role.eks_vpc_cni_role.arn

  tags = {
    Name = "${var.project_name}-vpc-cni"
  }

  depends_on = [aws_eks_node_group.main]
}

# CoreDNS Add-on for service discovery
resource "aws_eks_addon" "coredns" {
  cluster_name    = aws_eks_cluster.main.name
  addon_name      = "coredns"
  addon_version   = data.aws_eks_addon_version.coredns.version

  tags = {
    Name = "${var.project_name}-coredns"
  }

  depends_on = [aws_eks_node_group.main]
}

# kube-proxy Add-on for networking
resource "aws_eks_addon" "kube_proxy" {
  cluster_name    = aws_eks_cluster.main.name
  addon_name      = "kube-proxy"
  addon_version   = data.aws_eks_addon_version.kube_proxy.version

  tags = {
    Name = "${var.project_name}-kube-proxy"
  }

  depends_on = [aws_eks_node_group.main]
}
