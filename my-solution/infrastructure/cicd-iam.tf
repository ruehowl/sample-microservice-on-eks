# ===== CI/CD PIPELINE IAM ROLE =====

resource "aws_iam_role" "cicd_role" {
  name = "${var.project_name}-cicd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
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
        Resource = aws_ecr_repository.app.arn
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
        Resource = aws_eks_cluster.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = aws_iam_role.app_service_account.arn
      }
    ]
  })
}
