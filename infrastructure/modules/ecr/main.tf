
# ECR — Registry pour stocker les images Docker

resource "aws_ecr_repository" "app" {
  name                 = "ecr-${var.project_name}-${var.env}"
  image_tag_mutability = "IMMUTABLE"

  # Scan automatique des vulnérabilités
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "ecr-${var.project_name}-${var.env}"
    Env  = var.env
  }
}

# Politique de cycle de vie — garder seulement 10 images
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Garder les 10 dernières images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}