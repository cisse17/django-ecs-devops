
output "rds_endpoint" {
  value = aws_db_instance.rds.address # en prod je mets address au lieu de endpoint
}

output "rds_id" {
  value = aws_db_instance.rds.id
}