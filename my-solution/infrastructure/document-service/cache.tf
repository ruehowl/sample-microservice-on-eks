# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-subnet-group"
  subnet_ids = [local.private_subnet_1_id, local.private_subnet_2_id]

  tags = {
    Name = "${var.project_name}-elasticache-subnet-group"
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.project_name}-cache"
  engine               = "redis"
  node_type            = var.elasticache_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [local.elasticache_security_group_id]

  # Automatic backups
  snapshot_retention_limit = 5
  snapshot_window          = "03:00-05:00"

  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.elasticache.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  tags = {
    Name = "${var.project_name}-redis-cache"
  }

  depends_on = [aws_elasticache_subnet_group.main]
}
