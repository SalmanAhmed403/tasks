resource "aws_instance" "web" {
  ami           = "ami-047126e50991d067b"  // Ubuntu 24.04 in ap-southeast-1
  instance_type = "t2.medium"   
  
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  
// Add key pair for SSH access
  key_name = "task1"  

//Configure root volume (EBS)
  root_block_device {
    volume_size = 30               
    volume_type = "gp3"           
    encrypted   = true            
    tags = merge(
      var.project_tags,
      {
        Name = "task1-root-volume"
      }
    )
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Web Server Successfully Deployed</h1>" > /var/www/html/index.html
              EOF

  tags = merge(
    var.project_tags,
    {
      Name = "task1"
    }
  )
}