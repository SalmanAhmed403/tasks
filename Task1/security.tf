resource "aws_security_group" "web" {
  name        = "Task1-sg"
  description = "Security group for Task1"
  vpc_id      = aws_vpc.main.id

// HTTP access from anywhere  for the specific port
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP traffic"
  }

// SSH access for accessing the server
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH traffic"
  }

// Outbound internet access  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.project_tags,
    {
      Name = "task1-sg"
    }
  )
}