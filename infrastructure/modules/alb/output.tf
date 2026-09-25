
output "url_alb" {
  value = "http://${aws_alb.main.dns_name}"
}

output "alb_zone_id" {
  value       = aws_alb.main.zone_id
  description = "Zone ID de l'ALB"
}

# utilisé par ECS service
output "alb_target_group_arn" {
  value = aws_alb_target_group.main.arn
}

# utilisé par ECS service
output "alb_dns_name" {
  value = aws_alb.main.dns_name
}

# A AJOUTER - nécessaire pour CloudWatch
output "alb_arn_suffix" {
  value       = aws_alb.main.arn_suffix
  description = "ARN suffix pour les métriques CloudWatch"
}