# # ==========================================
# # AWS SECRETS MANAGER
# # ==========================================
# resource "aws_secretsmanager_secret" "django_secret_key" {
#   name = "${var.project_name}-${var.env}-secret-key"
  
#   tags = {
#     Env = var.env
#   }
# }

# resource "aws_secretsmanager_secret_version" "django_secret_key" {
#   secret_id     = aws_secretsmanager_secret.django_secret_key.id
#   secret_string = var.secret_key
# }

# resource "aws_secretsmanager_secret" "db_password" {
#   name = "${var.project_name}-${var.env}-db-password"

#   tags = {
#     Env = var.env
#   }
# }

# resource "aws_secretsmanager_secret_version" "db_password" {
#   secret_id     = aws_secretsmanager_secret.db_password.id
#   secret_string = var.db_password
# }