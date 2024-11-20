resource "aws_vpc" "flask_app_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "flask_app_igw" {
  vpc_id = aws_vpc.flask_app_vpc.id
}

resource "aws_subnet" "flask_app_subnet_a" {
  vpc_id                  = aws_vpc.flask_app_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "flask_app_subnet_b" {
  vpc_id                  = aws_vpc.flask_app_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "flask_app_sg" {
  name        = "flask-app-sg"
  description = "Allow HTTP access to Flask app"
  vpc_id      = aws_vpc.flask_app_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
