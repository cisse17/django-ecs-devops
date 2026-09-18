output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID du VPC créé"
}

output "rds_endpoint" {
  value       = module.rds.rds_endpoint
  description = "Endpoint de l'instance RDS"
}

output "load_balancer_url" {
  description = "URL du Load Balancer"
  value       = module.alb.url_alb
}


output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "IDs des sous-réseaux publics créés"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "IDs des sous-réseaux publics créés"
}


output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "URL ECR pour push les images Docker"
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "ecs_sg_id" {
  value = module.security.ecs_sg_id   
}