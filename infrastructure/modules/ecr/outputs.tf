output "repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "URL du registry ECR"
}

output "repository_arn" {
  value = aws_ecr_repository.app.arn
}