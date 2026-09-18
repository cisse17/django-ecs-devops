terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
}

# S3 BUCKET — stocke les fichiers tfstate
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-bassirou-2026"

  # lifecycle {
  #   prevent_destroy = true
  #   # Empêche "terraform destroy" de supprimer ce bucket
  #   # Protection contre les accidents — le state = données critiques
  #   # Pour supprimer : commenter cette ligne puis terraform destroy
  # }

  tags = {
    Name = "terraform-state-bassirou"
  }
}


# VERSIONING — historique des states
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}


# CHIFFREMENT — sécurité des données
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {

  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"

    }
  }
}


# BLOCAGE ACCÈS PUBLIC — isolation totale
resource "aws_s3_bucket_public_access_block" "terraform_state" {

  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  # Bloque les ACL publiques sur les objets
  # ACL = liste de qui peut accéder à quoi

  block_public_policy     = true
  # Bloque les policies S3 qui rendraient le bucket public

  ignore_public_acls      = true
  # Ignore les ACL publiques même si quelqu'un essaie d'en ajouter

  restrict_public_buckets = true
  # Restreint l'accès aux seuls services AWS autorisés
  # Résultat final : SEUL mon pipeline GitHub Actions peut
  # lire/écrire dans ce bucket via les credentials AWS 
}

