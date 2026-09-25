
# SNS — notifications par email
resource "aws_sns_topic" "alerts" {
  name = "alerts-${var.project_name}-${var.env}"

  tags = {
    Name = "alerts-${var.project_name}-${var.env}"
    Env  = var.env
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
  # Je vais recevoir un email de confirmation à valider !
}


# DASHBOARD - vue d'ensemble
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "dashboard-${var.project_name}-${var.env}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ECS CPU Utilization"
          metrics = [[
            "AWS/ECS",
            "CPUUtilization",
            "ServiceName", "service-django-${var.project_name}-${var.env}",
            "ClusterName", "cluster-${var.project_name}-${var.env}"
          ]]
          period = 300
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ECS Memory Utilization"
          metrics = [[
            "AWS/ECS",
            "MemoryUtilization",
            "ServiceName", "service-django-${var.project_name}-${var.env}",
            "ClusterName", "cluster-${var.project_name}-${var.env}"
          ]]
          period = 300
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB Response Time"
          metrics = [[
            "AWS/ApplicationELB",
            "TargetResponseTime",
            "LoadBalancer", var.alb_arn_suffix
          ]]
          period = 300
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB 5XX Errors"
          metrics = [[
            "AWS/ApplicationELB",
            "HTTPCode_Target_5XX_Count",
            "LoadBalancer", var.alb_arn_suffix
          ]]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "RDS CPU"
          metrics = [[
            "AWS/RDS",
            "CPUUtilization",
            "DBInstanceIdentifier",
            "mydatabase-${var.project_name}-${var.env}"
          ]]
          period = 300
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "RDS Connections"
          metrics = [[
            "AWS/RDS",
            "DatabaseConnections",
            "DBInstanceIdentifier",
            "mydatabase-${var.project_name}-${var.env}"
          ]]
          period = 300
          stat   = "Average"
          region = var.aws_region
          view   = "timeSeries"
        }
      }
    ]
  })
}


# ALARM - CPU trop élevé
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-${var.project_name}-${var.env}"
  alarm_description   = "CPU ECS dépasse 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = "cluster-${var.project_name}-${var.env}"
    ServiceName = "service-django-${var.project_name}-${var.env}"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Env = var.env
  }
}


# ALARM : Trop d'erreurs 500 (5xx)
resource "aws_cloudwatch_metric_alarm" "high_5xx" {
  alarm_name          = "high-5xx-${var.project_name}-${var.env}"
  alarm_description   = "Trop d'erreurs 5xx sur l'ALB"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60 # test 1 minute au lieu de 5 minute (300)
  statistic           = "Sum"
  threshold           = 1 # test 1 minute au lieu de 5 minute
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Env = var.env
  }
}