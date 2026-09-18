
# IAM ROLE — ECS peut pull depuis ECR
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecs-task-execution-${var.project_name}-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Policy AWS managée pour ECS
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# TASK DEFINITION 
resource "aws_ecs_task_definition" "django" {
  family                   = "django-${var.project_name}-${var.env}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  # CPU et RAM pour le container
  cpu    = var.task_cpu
  memory = var.task_memory

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  # La définition du container en JSON
  container_definitions = jsonencode([
    {
      name  = "django"
      image = "${var.ecr_image_url}:${var.image_tag}"

      # Ports exposés
      portMappings = [{
        containerPort = 8000
        protocol      = "tcp"
      }]

      # Variables d'environnement Django
      environment = [
        { name = "DEBUG",       value = "False" },
        { name = "ALLOWED_HOSTS", value = var.allowed_hosts },
        { name = "DB_NAME",     value = var.db_name },
        { name = "DB_USER",     value = var.db_username },
        { name = "DB_HOST",     value = var.db_host },
        { name = "DB_PORT",     value = "5432" },

        { name = "DB_PASSWORD",      value = var.db_password },
        { name = "SECRET_KEY",       value = var.secret_key },

        { name = "CELERY_BROKER_URL",    value = "redis://localhost:6379/0" },
        { name = "CELERY_RESULT_BACKEND", value = "redis://localhost:6379/0" },
      ]


      # Logs vers CloudWatch
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/django-${var.project_name}-${var.env}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "django"
        }
      }

      # Health check
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/admin/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "task-django-${var.project_name}-${var.env}"
    Env  = var.env
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "django" {
  name              = "/ecs/django-${var.project_name}-${var.env}"
  retention_in_days = 7   # garde les logs 7 jours

  tags = {
    Env = var.env
  }
}
