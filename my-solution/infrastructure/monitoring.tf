# ===== CLOUDWATCH LOG GROUPS =====

# CloudWatch Log Group for EKS Cluster Logs
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.project_name}-eks-cluster/cluster"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-eks-cluster-logs"
  }
}

# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/eks/${var.project_name}-eks-cluster/application"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-app-logs"
  }
}

# CloudWatch Log Group for ALB Logs
resource "aws_cloudwatch_log_group" "alb" {
  name              = "/aws/alb/${var.project_name}-alb"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-alb-logs"
  }
}

# CloudWatch Log Group for ElastiCache
resource "aws_cloudwatch_log_group" "elasticache" {
  name              = "/aws/elasticache/${var.project_name}-redis"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-elasticache-logs"
  }
}

# ===== CLOUDWATCH DASHBOARD =====

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            [".", "RequestCount", { stat = "Sum" }],
            [".", "HTTPCode_Target_2XX_Count", { stat = "Sum" }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum" }],
            [".", "HealthyHostCount", { stat = "Average" }],
            [".", "UnHealthyHostCount", { stat = "Average" }],
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, @message | stats count() by bin(5m)"
          region  = var.aws_region
          title   = "Application Log Volume"
          logGroupNames = [
            aws_cloudwatch_log_group.app.name
          ]
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_node_count", { stat = "Average" }],
            [".", "cluster_failed_node_count", { stat = "Average" }],
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EKS Node Metrics"
        }
      }
    ]
  })
}

# ===== CLOUDWATCH ALARMS =====

# Alarm for ALB Target Response Time
resource "aws_cloudwatch_metric_alarm" "alb_response_time" {
  alarm_name          = "${var.project_name}-alb-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0.5  # 500ms
  alarm_description   = "Alert when ALB response time is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${var.project_name}-alb-response-time"
  }
}

# Alarm for ALB 5xx Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when ALB receives more than 10 5xx errors in 5 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = {
    Name = "${var.project_name}-alb-5xx-errors"
  }
}

# Alarm for Unhealthy Targets
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when there are unhealthy targets"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  tags = {
    Name = "${var.project_name}-alb-unhealthy-hosts"
  }
}

# Alarm for EKS Node Issues
resource "aws_cloudwatch_metric_alarm" "eks_failed_nodes" {
  alarm_name          = "${var.project_name}-eks-failed-nodes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "cluster_failed_node_count"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alert when EKS nodes are in failed state"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_eks_cluster.main.name
  }

  tags = {
    Name = "${var.project_name}-eks-failed-nodes"
  }
}

# CloudWatch Log Metric Filter for Application Errors
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "${var.project_name}-app-errors"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = "[ERROR]"

  metric_transformation {
    name          = "ApplicationErrorCount"
    namespace     = "${var.project_name}/Application"
    value         = "1"
    default_value = 0
  }
}

# Alarm for Application Errors
resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "${var.project_name}-app-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApplicationErrorCount"
  namespace           = "${var.project_name}/Application"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when application error rate is high"
  treat_missing_data  = "notBreaching"

  tags = {
    Name = "${var.project_name}-app-errors"
  }
}
