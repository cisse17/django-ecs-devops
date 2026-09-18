
# # variable "ami" {  
# #     description = "ID de l'AMI"
# #     type = string
# #     # default = "ami-007dcf089b8078f1a"



# # }

# # variable "subnet_id" {
# #     description = "ID du subnet"
# #     type = string

# # }

# # variable "security_group_ids" {
# #     description = "ID du security group de l'instance EC2"
# #     type = list(string)

# # }

# # variable "env" {
# #   type = string
# # }

# # variable "project_name" {
# #   type = string
# #   default = "bassirou"
# # }

# # variable "instance_type" {
# #     type = string
# #     # default = "t2.micro"
# # }

# # variable "key_name" {
# #     type = string
# #     # default = "terraformcloud"
# # }



# # exo

# variable "ami" {
#     type = string
#     description = "ID de l'AMI"

# }

# variable "subnet_id" {
#     type = string
#     description = "ID du subnet pour notre instance ec2"
# }

# variable "security_group_ids" {
#     type = list(string)
#     description = "ID du security group de l'instance EC2"
# }

# variable "instance_type" {
#     type = string 
#     description = "Type de l'instance"
# }

# variable "key_name" {
#     type = string
#     description = "Nom de la key pair pour l'instance EC2"
# }

# variable "env" {
#     type = string
#     description = "environnement (dev, staging, prod)"
# }

# variable "project_name" {
#     type = string
#     description = "Nom du projet"
# }



variable "user_data" {
  type        = string
  description = "Script à exécuter au démarrage de l'instance"
  default     = ""
}

variable "ami" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "key_name" {
  type    = string
  default = "terraformcloud"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "project_name" {
  type = string
}


variable "env" {
  type        = string
  description = "Environnement (dev, staging, prod)"
  # default     = "dev"
}
