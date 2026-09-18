

# resource "aws_instance" "instance_vm"{
#   ami = var.ami
#   instance_type = var.instance_type
#   subnet_id = var.subnet_id
#   key_name = var.key_name
#   vpc_security_group_ids = var.security_group_ids

#   # ← AJOUTÉ
#   user_data = var.user_data != "" ? var.user_data : null

#   tags = {
#     Name = "instance-vm-${var.project_name}"
#     Env = var.env
#   }
# }


resource "aws_instance" "vm_instance" {
  ami             = var.ami
  instance_type   = var.instance_type
  subnet_id       = var.subnet_id
  security_groups = var.security_group_ids
  key_name        = var.key_name


  user_data = var.user_data != "" ? var.user_data : null


  tags = {
    Name = "instance-${var.project_name}"
  }
}

