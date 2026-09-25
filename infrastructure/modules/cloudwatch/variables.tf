# On définit ici nos variables pour notre cloudwatch
variable "project_name" { type = string }
variable "env"          { type = string }
variable "aws_region"   { type = string }
variable "alert_email"  { type = string }
variable "alb_arn_suffix" {
  type        = string
  description = "ARN suffix de l'ALB pour les métriques CloudWatch"
}