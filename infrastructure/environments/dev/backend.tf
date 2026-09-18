terraform {
  backend "s3" {
    bucket       = "terraform-state-bassirou-2026"
    key          = "dev/terraform.tfstate"
    region       = "eu-west-3"
    use_lockfile = true   # new version qui gére le lock 
    encrypt      = true
  }
}