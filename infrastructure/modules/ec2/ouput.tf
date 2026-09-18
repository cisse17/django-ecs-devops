
# output "instance_id" {
#   value = aws_instance.instance_vm.id
#   description = "ID de l'instance EC2"
# }

# output "instance_public_ip" {
#   value = aws_instance.instance_vm.public_ip
#   description = "Adresse IP publique de l'instance EC2"
# }

# output "public_dns" {
#   value = aws_instance.instance_vm.public_dns
#   description = "DNS public de l'instance EC2"
# }

# output "ssh_command"{
#   value = "ssh -i ./key/${var.key_name}.pem ubuntu@${aws_instance.instance_vm.public_ip}"
#   description = "Commande SSH pour se connecter à l'instance EC2"
# }

output "ec2_public_ip" {
  value = aws_instance.vm_instance.public_ip
}

output "instance_id" {
  value = aws_instance.vm_instance.id
}

output "public_dns" {
  value = aws_instance.vm_instance.public_dns
}

output "ssh_command" {
  value = "ssh -i ./key/${var.key_name}.pem ubuntu@${aws_instance.vm_instance.public_ip}"
}

