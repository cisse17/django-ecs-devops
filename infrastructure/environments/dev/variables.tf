variable "aws_region" {
  type        = string
  description = "La région d'hébergement pour les ressources AWS"
  default     = "eu-west-3"

}

variable "env" {
  type        = string
  description = "environnement (dev, staging, prod)"

}

variable "project_name" {
  type        = string
  description = "Nom du projet"

}

# rds
variable "db_name" {
  type    = string
  default = "dbbassirou"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}

variable "db_password" {
  type      = string
  sensitive = true
}


# ajouté pour ecs
variable "secret_key" {
  type      = string
  sensitive = true
}

variable "allowed_hosts" {
  type    = string
  default = "*"
}

variable "image_tag" {
  description = "Git SHA / Docker image tag à déployer"
  type        = string
}