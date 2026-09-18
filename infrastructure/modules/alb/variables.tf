variable "vpc_id" {
  type = string
  description = "ID du vpc"
}

variable "project_name"{
  type = string
  description = "Nom du project"
  default = "Basssirou"
}
variable "env" {
 type = string
 default = "dev" 
}

variable "subnet_ids" {
  type = list(string)
  description = "Liste des IDs des sous réseaux "

}

variable "security_group_id" {
  type = string
  description = "ID du Security group de l'instance ec2 "
}

# plus besoin de liste de instances IDs