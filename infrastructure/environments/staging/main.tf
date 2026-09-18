terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0"
    }
  }

  required_version = ">= 0.14"
}

provider "aws" {
  region = var.aws_region

}

module "vpc" {
  source = "../../modules/vpc"
  project_name = var.project_name
  env          = var.env
}

module "security" {
  source = "../../modules/security"

  vpc_id       = module.vpc.vpc_id
  project_name = var.project_name
  env          = var.env
}

module "rds" {
  source            = "../../modules/rds"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security.rds_sg_id
  db_name           = var.db_name
  db_password       = var.db_password
  db_username       = var.db_username
  project_name      = var.project_name
  env               = var.env
}


module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.project_name
  env          = var.env
}


# Ajouter le module ECS
module "ecs" {
  source = "../../modules/ecs"

  project_name      = var.project_name
  env               = var.env
  aws_region        = var.aws_region

  # Image Docker depuis ECR
  ecr_image_url     = module.ecr.repository_url

  # Réseau
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security.ecs_sg_id

  # ALB
  target_group_arn  = module.alb.alb_target_group_arn

  # RDS
  db_host           = module.rds.rds_endpoint

  # Django config
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  secret_key        = var.secret_key
  allowed_hosts     = var.allowed_hosts

  # Resources Fargate
  task_cpu          = "256"
  task_memory       = "512"
  desired_count     = 1
}


module "alb" {
  source            = "../../modules/alb"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_id = module.security.alb_sg_id
  env               = var.env
  project_name      = var.project_name
}