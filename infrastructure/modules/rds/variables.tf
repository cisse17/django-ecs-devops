
variable "project_name" {
  type = string
}
variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "db_name" {
  type    = string
  default = "dbbassirou"
}

variable "db_username" {
  type    = string
  default = "Admin"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = "Admin123"
}

variable "subnet_ids" {
  type = list(string)
}