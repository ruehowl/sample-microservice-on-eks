# ===== GITHUB OIDC PROVIDER =====

# Get GitHub OIDC certificate thumbprint
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Create GitHub OIDC Identity Provider
resource "aws_iam_openid_connect_provider" "github" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
  url             = "https://token.actions.githubusercontent.com"

  tags = {
    Name = "${var.project_name}-github-oidc-provider"
  }
}

# ===== CI/CD PIPELINE IAM ROLE =====

resource "aws_iam_role" "cicd_role" {
  name = "${var.project_name}-cicd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:SleekTechPteLtd-Assessments/principal-sre-assessment-rahul-varghese:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-cicd-role"
  }
}

# Policy for CI/CD to push images to ECR
resource "aws_iam_role_policy" "cicd_ecr_policy" {
  name = "${var.project_name}-cicd-ecr-policy"
  role = aws_iam_role.cicd_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken"
        ]
        Resource = local.ecr_repository_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for CI/CD to update EKS deployment
resource "aws_iam_role_policy" "cicd_eks_policy" {
  name = "${var.project_name}-cicd-eks-policy"
  role = aws_iam_role.cicd_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = local.eks_cluster_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = local.app_service_account_arn
      }
    ]
  })
}

