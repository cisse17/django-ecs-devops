# ECS SERVICE
resource "aws_ecs_service" "django" {
  name            = "service-django-${var.project_name}-${var.env}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.django.arn

  # Nombre de containers à faire tourner
  desired_count = var.desired_count  

  launch_type = "FARGATE"

  # Réseau
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  # Connecter au Load Balancer
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "django"
    container_port   = 8000
  }

  # Déploiement sans interruption
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = {
    Name = "service-django-${var.project_name}-${var.env}"
    Env  = var.env
  }
}