output "instance1_public_ip" {
  description = "Public IP address of first EC2 instance"
  value       = aws_instance.ec2_az1.public_ip
}

output "instance2_public_ip" {
  description = "Public IP address of second EC2 instance"
  value       = aws_instance.ec2_az2.public_ip
}

output "rds_endpoint" {
  description = "Endpoint of RDS instance"
  value       = aws_db_instance.mysql.endpoint
}
