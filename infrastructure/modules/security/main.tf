# ECS
resource "aws_security_group" "ecs" {
  name        = "ecs-sg-${var.project_name}"
  description = "security group pour notre ecs" 
  vpc_id      = var.vpc_id

  egress {
    description = "all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-${var.project_name}"
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-sg-${var.project_name}"
  description = "security group database"
  vpc_id      = var.vpc_id

  ingress {
    description     = "allow PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    # description     = "allow mysql"
    # from_port       = 3306
    # to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    description = "all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-sg-${var.project_name}"
  description = "security group Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "allow http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_alb_to_ecs" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs.id
  source_security_group_id = aws_security_group.alb.id
  description              = "allow traffic from ALB to ECS"
}


