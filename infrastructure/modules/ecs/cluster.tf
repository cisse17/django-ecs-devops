
# ECS CLUSTER
resource "aws_ecs_cluster" "main" {
  name = "cluster-${var.project_name}-${var.env}"

  # Container Insights = monitoring des containers
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "cluster-${var.project_name}-${var.env}"
    Env  = var.env
  }
}

# Capacity Provider — utilise FARGATE
resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}