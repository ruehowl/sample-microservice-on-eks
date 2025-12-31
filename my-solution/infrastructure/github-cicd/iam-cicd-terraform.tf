# ===== TERRAFORM CI/CD IAM ROLE =====

resource "aws_iam_role" "terraform_cicd_role" {
  name = "${var.project_name}-terraform-cicd-role"

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
    Name = "${var.project_name}-terraform-cicd-role"
  }
}

# Policy for Terraform to manage infrastructure
resource "aws_iam_role_policy" "terraform_infrastructure_policy" {
  name = "${var.project_name}-terraform-infrastructure-policy"
  role = aws_iam_role.terraform_cicd_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticache:*",
          "rds:*",
          "s3:*",
          "ecr:*",
          "eks:*",
          "iam:*",
          "elasticloadbalancing:*",
          "logs:*",
          "cloudwatch:*",
          "kms:*",
          "secretsmanager:*",
          "ssm:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
      }
    ]
  })
}

# Policy for Terraform state management
resource "aws_iam_role_policy" "terraform_state_policy" {
  name = "${var.project_name}-terraform-state-policy"
  role = aws_iam_role.terraform_cicd_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-terraform-state",
          "arn:aws:s3:::${var.project_name}-terraform-state/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.project_name}-terraform-state-lock"
      }
    ]
  })
}
