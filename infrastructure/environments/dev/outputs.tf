output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID du VPC créé"
}

output "rds_endpoint" {
  value       = module.rds.rds_endpoint
  description = "Endpoint de l'instance RDS"
}

# je commente pour l'instant vu que on va faire ecr et ecs
# output "ec2_public_ip" {
#   value       = module.ec2.ec2_public_ip
#   description = "Adresse IP publique de l'instance EC2"
# }
# je commente pour l'instant vu que on va faire ecr et ecs
# output "ec2_public_dns" {
#   value       = module.ec2.public_dns
#   description = "Nom de domaine public de l'instance EC2"
# }


# output "alb_dns_name" {
#   value       = module.alb.alb_dns_name
#   description = "Nom de domaine de l'ALB"
# }

output "load_balancer_url" {
  description = "URL du Load Balancer"
  value       = module.alb.url_alb
}

# je commente pour l'instant vu que on va faire ecr et ecs
# output "ssh_connection" {
#   value       = module.ec2.ssh_command
#   description = "Commande SSH pour se connecter à l'instance EC2"
# }


output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "IDs des sous-réseaux publics créés"
}


output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "URL ECR pour push les images Docker"
}

# POUR ECS
output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}