
resource "aws_db_subnet_group" "main" {
  name       = "main-db-subnet-group-${var.project_name}-${var.env}"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "db-subnet-group-${var.project_name}-${var.env}"
  }
}

resource "aws_db_instance" "rds" {
  identifier = "mydatabase-${var.project_name}-${var.env}"

  # engine         = "mysql"
  # engine_version = "8.0"
  engine         = "postgres"
  engine_version = "16.9"
  instance_class = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = false

  skip_final_snapshot     = true
  multi_az                = false
  deletion_protection     = false
  backup_retention_period = 0

  tags = {
    Name = "rds-instance-${var.project_name}"
  }


}