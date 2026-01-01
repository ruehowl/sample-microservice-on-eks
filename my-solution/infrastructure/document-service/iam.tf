# ===== APPLICATION SERVICE ACCOUNT IAM ROLE (IRSA) =====

# Look up the EKS-created OIDC provider so this component can manage IRSA roles
# without owning the provider resource itself.
data "aws_iam_openid_connect_provider" "cluster" {
  arn = local.oidc_provider_arn
}

resource "aws_iam_role" "app_service_account" {
  name = "${var.project_name}-app-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.cluster.arn
        }
        Condition = {
          StringEquals = {
            "${local.oidc_provider_hostpath}:sub" = "system:serviceaccount:default:document-service"
            "${local.oidc_provider_hostpath}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-app-sa-role"
  }
}

# Policy for application to access S3 (scoped to this stack's bucket)
resource "aws_iam_role_policy" "app_s3_policy" {
  name = "${var.project_name}-app-s3-policy"
  role = aws_iam_role.app_service_account.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.document_storage.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.document_storage.arn
      }
    ]
  })
}

# Policy for application to access ElastiCache
resource "aws_iam_role_policy" "app_elasticache_policy" {
  name = "${var.project_name}-app-elasticache-policy"
  role = aws_iam_role.app_service_account.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeReplicationGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for application to access CloudWatch Logs
resource "aws_iam_role_policy" "app_logs_policy" {
  name = "${var.project_name}-app-logs-policy"
  role = aws_iam_role.app_service_account.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}
