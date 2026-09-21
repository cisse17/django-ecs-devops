terraform {
  backend "s3" {
    bucket = "terraform-state-bassirou-2026" # utilise le méme remote state s3 de mes env
    key    = "shared/ecr/terraform.tfstate"
    region = "eu-west-3"
  }
}