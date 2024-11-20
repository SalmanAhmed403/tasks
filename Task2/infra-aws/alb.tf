resource "aws_lb" "flask_app_alb" {
  name               = "flask-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.flask_app_sg.id]
  subnets            = [
    aws_subnet.flask_app_subnet_a.id,
    aws_subnet.flask_app_subnet_b.id
  ]
}

resource "aws_lb_target_group" "flask_app_target_group" {
  name     = "flask-app-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.flask_app_vpc.id
}

resource "aws_lb_listener" "flask_app_listener" {
  load_balancer_arn = aws_lb.flask_app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_app_target_group.arn
  }
}
