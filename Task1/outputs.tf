output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "instance_public_ip" {
  description = "The public IP of the web server"
  value       = aws_instance.web.public_ip
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.web.id
}