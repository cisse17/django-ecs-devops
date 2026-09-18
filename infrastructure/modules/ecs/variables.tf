variable "project_name" { type = string }
variable "env"          { type = string }
variable "aws_region" {
     type = string 
     default = "eu-west-3" 
     }

# Image Docker
variable "ecr_image_url" { type = string }

variable "image_tag" { 
     description = "Image tag dokcer" 
     type = string 
     default="latest"
     }

# Réseau
variable "vpc_id"           { type = string }
variable "subnet_ids"        { type = list(string) }
variable "security_group_id" { type = string }

# ALB
variable "target_group_arn" { type = string }

# Django
variable "db_host"       { type = string }
variable "db_name"       { type = string }
variable "db_username"   { type = string }
variable "db_password"  { type = string }
variable "secret_key"   { type = string }
variable "allowed_hosts" { type = string }

# Resources
variable "task_cpu" { 
    type = string  
    default = "256" 
    }
    
variable "task_memory" {
     type = string  
     default = "512" 
     }

variable "desired_count" {
     type = number  
     default = 1 
     }