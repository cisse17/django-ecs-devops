# POUR ECS 
resource "aws_alb" "main" {
  name               = "alb-${var.project_name}-${var.env}"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = [var.security_group_id]

  enable_deletion_protection = false

  tags = {
    Name = "alb-${var.project_name}"
    Env  = var.env
  }
}

resource "aws_alb_target_group" "main" {
  name     = "alb-tg-${var.project_name}-${var.env}"
  protocol = "HTTP"
  port     = 8000        # 8000 pour Django/Gunicorn
  vpc_id   = var.vpc_id
  target_type = "ip"     # Important : "ip" pour ECS Fargate
                         #  "instance" c'était pour EC2

  health_check {
    enabled             = true
    path                = "/health/" 
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"   
  }

  deregistration_delay = 30

  tags = {
    Name = "target-group-${var.project_name}-${var.env}"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.main.arn
  }
}
