
# OIDC PROVIDER — AWS fait confiance à GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name = "github-actions-oidc"
  }
}


# IAM ROLE — ce que GitHub Actions peut faire

resource "aws_iam_role" "github_actions" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            # SEULEMENT mon repo GitHub peut utiliser ce rôle
            "token.actions.githubusercontent.com:sub" = [
            # Nouveau format immutable subject (GitHub depuis juillet 2026)
            "repo:cisse17@119404406/django-ecs-devops@1374481008:*" 
            ]
            
          }
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "github-actions-role"
  }
}


# IAM POLICY — les permissions exactes

resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Terraform a besoin de ces permissions pour gérer l'infra
        Effect = "Allow"
        Action = [
          # EC2
          "ec2:*",
          # RDS
          "rds:*",
          # VPC
          "vpc:*",
          # ALB
          "elasticloadbalancing:*",
          # S3 — pour le remote state
          "s3:*",

          # IAM — pour créer des rôles si besoin
          "iam:*",

          "ecr:*",          # AJOUTER
          "ecs:*",          
          "logs:*",         
          "secretsmanager:*",    
        ]
        Resource = "*"
      }
    ]
  })
}











