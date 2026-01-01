# Application Security Group
resource "aws_security_group" "app" {

  name        = "${var.project_name}-app-sg"
  description = "Security group for application pods"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    description = "Allow traffic from within the VPC"
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [local.private_subnet_1_cidr, local.private_subnet_2_cidr]
    description = "Allow all internal traffic within private subnets"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# ElastiCache Security Group
resource "aws_security_group" "elasticache" {

  name        = "${var.project_name}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "Allow Redis access from application pods"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-elasticache-sg"
  }
}
