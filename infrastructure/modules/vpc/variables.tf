
variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16" 
}

variable "availability_zones" {
  type = list(string)
  default = [ "eu-west-3a", "eu-west-3b" ]
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = [ "10.0.1.0/24", "10.0.2.0/24" ]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = [ "10.0.3.0/24", "10.0.4.0/24" ]
}

variable "env" {
  description = "environnement (prod, dev, stage)"
  type = string
  default = "dev"
}

variable "project_name" {
  type = string
  default = "bassirou"
}