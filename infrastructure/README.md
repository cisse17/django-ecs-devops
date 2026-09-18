
# Terraform AWS Infrastructure

Infrastructure AWS modulaire construite avec Terraform dans le cadre d'un projet 
incluant AWS, Terraform, Pipeline CI/CD, Remote State, FinOps, Kubernetes et du 
monitoring — dans le but de partager des connaissances sur le Cloud et les pratiques DevOps.

L'objectif est d'appliquer les bonnes pratiques d'Infrastructure as Code (IaC) en 
créant des modules Terraform réutilisables pour différents composants AWS et gérer 
le cycle de vie complet d'un produit cloud.

L'objectif final est de déployer une application web Django avec toutes les 
technologies nécessaires pour assurer son fonctionnement, son monitoring et sa 
scalabilité.

---

## Architecture

![Architecture AWS](./architecture.png)

---

## Modules disponibles

### VPC Module
Création d'un réseau AWS complet :
- VPC
- Public Subnets
- Private Subnets
- Internet Gateway
- NAT Gateway
- Route Tables

### Security Group Module
Gestion des règles de sécurité AWS :
- Ingress/Egress Rules
- Variables personnalisables
- Outputs réutilisables

### EC2 Module
Déploiement d'instances de calcul :
- Instance EC2
- User Data (installation automatique)
- Association avec Security Groups
- Outputs : IP publique, DNS, commande SSH

### RDS Module
Déploiement d'une base de données Amazon RDS :
- Instance MySQL
- Subnet Group privé
- Association avec Security Groups
- Paramètres configurables par environnement

### ALB Module
Load Balancer applicatif :
- Application Load Balancer
- Target Group
- Listener HTTP
- Répartition de charge entre EC2

---

## Project Structure

```text
.
├── bootstrap/                    # Remote State — à exécuter UNE SEULE FOIS
│   ├── main.tf                   # Crée S3 bucket + DynamoDB
│   └── outputs.tf
│   └── oidc.tf
│
├── environments/                 # Environnements séparés
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── backend.tf            # Remote state S3 dev
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── backend.tf            # Remote state S3 staging
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── backend.tf            # Remote state S3 prod
│       └── terraform.tfvars
│
├── modules/                      # Modules réutilisables
│   ├── vpc/
│   ├── security/
│   ├── ecs/
│   ├── rds/
│   └── alb/
│
└── .github/
    └── workflows/
        └── terraform.yml         # Pipeline CI/CD
```

---

## Prerequisites

Avant de démarrer, assurez-vous d'avoir :
- Terraform >= 1.5.0
- AWS CLI configuré
- Un compte AWS
- Un compte GitHub

Vérifier les versions :
```bash
terraform version
aws --version
```

---

## Getting Started

### 1. Cloner le repo
```bash
git clone https://github.com/cisse17/terraform-aws-infrastructure.git
cd terraform-aws-infrastructure
```

### 2. Configurer AWS CLI
```bash
aws configure
# AWS Access Key ID     : ***************
# AWS Secret Access Key : ***************
# Default region        : eu-west-3
# Default output format : json
```

### 3. Créer le Remote State (une seule fois)
```bash
cd bootstrap
terraform init
terraform apply
```

### 4. Initialiser un environnement
```bash
cd environments/dev
terraform init    # Se connecte automatiquement au backend S3
terraform plan -var="db_password=TON_MOT_DE_PASSE"
terraform apply -var="db_password=TON_MOT_DE_PASSE"
```

### 5. Détruire l'infrastructure
```bash
terraform destroy -var="db_password=TON_MOT_DE_PASSE"
```

---

## CI/CD Pipeline

Le pipeline GitHub Actions se déclenche automatiquement :

| Événement    | Action | Description |
|--------------|--------|-------------|
| Pull Request | Plan automatique | Lance le plan sur dev + staging + prod en parallèle |
| workflow_dispatch | Apply manuel | Déploie sur l'environnement choisi |
| workflow_dispatch | Destroy manuel | Supprime les ressources de l'environnement choisi |

### Secrets GitHub requis

Settings → Secrets and variables → Actions

AWS_ACCESS_KEY_ID → Clé d'accès AWS
AWS_SECRET_ACCESS_KEY → Clé secrète AWS
DB_PASSWORD → Mot de passe RDS


### Lancer un déploiement manuel

GitHub → Actions → Terraform CI/CD → Run workflow
→ action : apply
→ environment : dev
→ Run workflow


---

## Remote State S3

Le state Terraform est stocké sur S3 pour permettre :
- Le partage du state entre les membres de l'équipe
- Le verrouillage du state (évite les modifications simultanées)
- L'historique des versions du state

terraform-state-bassirou-2026/
├── dev/terraform.tfstate
├── staging/terraform.tfstate
└── prod/terraform.tfstate


---

## Environnements

| Environnement | Instance EC2 | RDS | Usage |
|---------------|-------------|-----|-------|
| dev | t2.micro | db.t3.micro | Développement et tests |
| staging | t2.small | db.t3.small | Validation avant prod |
| prod | t2.medium | db.t3.medium | Production |

---

## Learning Objectives

Ce projet vous permet de pratiquer :
- La création de modules Terraform réutilisables
- L'organisation multi-environnements (dev/staging/prod)
- Les pipelines CI/CD avec GitHub Actions
- La gestion du Remote State Terraform
- Les bonnes pratiques IaC en entreprise
- Le cycle de vie complet d'une infrastructure AWS

---

## Technologies

![Terraform](https://img.shields.io/badge/Terraform-1.5.0-purple)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange)
![GitHub Actions](https://img.shields.io/badge/GitHub-Actions-blue)

- Terraform
- AWS (VPC, EC2, RDS, ALB, S3, DynamoDB)
- GitHub Actions (CI/CD)
- Infrastructure as Code (IaC)

---

## Roadmap

- [x] VPC Module
- [x] Security Group Module
- [x] EC2 Module
- [x] RDS Module
- [x] ALB Module
- [x] Multi-environment (dev/staging/prod)
- [x] GitHub Actions CI/CD Pipeline
- [x] Remote State S3 + DynamoDB Locking
- [x] Remote State S3 + use_lockfile (sans DynamoDB)
- [ ] Architecture diagram
- [ ] OIDC (suppression des clés AWS dans GitHub Secrets)
- [ ] Application Django
- [ ] Kubernetes (EKS)
- [ ] Monitoring (Prometheus + Grafana)
- [ ] FinOps

---

## Author

**Bassirou Mbacké CISSÉ**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue)](https://www.linkedin.com/in/bassirou-mback%C3%A9-ciss%C3%A9-683529263/)
[![YouTube](https://img.shields.io/badge/YouTube-Subscribe-red)](https://www.youtube.co