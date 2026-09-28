# Guide complet de déploiement AWS / ECS / Docker / GitHub Actions

Ce document décrit le déploiement complet du projet **Django + Docker + AWS ECS Fargate + RDS PostgreSQL + Application Load Balancer + Terraform + GitHub Actions**.

L'objectif est de comprendre non seulement **comment déployer l'application**, mais également **pourquoi chaque étape est nécessaire**.

---

# 1. Architecture générale

Le projet utilise l'architecture suivante :

```text
                         Internet
                            │
                            ▼
                  ┌───────────────────┐
                  │   ALB public      │
                  │ Application LB    │
                  └─────────┬─────────┘
                            │
                            ▼
              ┌──────────────────────────┐
              │       ECS Fargate        │
              │                          │
              │   Django + Gunicorn      │
              │   Private Subnets        │
              └────────────┬─────────────┘
                           │
                           ▼
              ┌──────────────────────────┐
              │      RDS PostgreSQL      │
              │      Private Subnets     │
              └──────────────────────────┘
```

Les ressources sont réparties de cette manière :

| Ressource      | Réseau             |
| -------------- | ------------------ |
| ALB            | Subnets publics    |
| ECS Fargate    | Subnets privés     |
| RDS PostgreSQL | Subnets privés     |
| Docker / ECR   | Service AWS        |
| GitHub Actions | Accès AWS via OIDC |

L'utilisateur final ne communique donc pas directement avec ECS.

Le flux est :

```text
Navigateur
    ↓
ALB public
    ↓
ECS Fargate privé
    ↓
Django / Gunicorn
    ↓
RDS PostgreSQL privé
```

---

# 2. Structure du projet

Le projet est organisé ainsi :

```text
django-ecs-devops/
│
├── app/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── requirements.txt
│   └── ...
│
├── infrastructure/
│   │
│   ├── bootstrap/
│   │   └── ...
│   │
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   │
│   ├── modules/
│   │   ├── alb/
│   │   ├── ecr/
│   │   ├── ecs/
│   │   ├── rds/
│   │   ├── security/
│   │   └── vpc/
│   │
│   ├── shared/
│   │   └── ecr/
│   │
│   └── key/
│
├── docs/
│   ├── bootstrap-aws-ecs.md
│   └── oidc-github-aws.md
│
└── .github/
    └── workflows/
        ├── terraform.yml
        └── django.yml
```

---

# 3. Deux notions importantes : Bootstrap Terraform et image Docker Bootstrap

Il ne faut pas confondre les deux.

## 3.1 `infrastructure/bootstrap/`

Ce dossier contient le **bootstrap Terraform de l'infrastructure**.

Il sert notamment à créer :

```text
S3
  ↓
Terraform remote state

GitHub
  ↓
OIDC
  ↓
AWS IAM Role
  ↓
GitHub Actions
```

Son rôle est donc de préparer AWS pour Terraform et GitHub Actions.

---

## 3.2 L'image Docker `:bootstrap`

L'image Docker :

```text
ecr-bassirou:bootstrap
```

est complètement différente.

Elle sert uniquement à résoudre le problème initial suivant :

```text
Terraform veut créer ECS
        ↓
ECS a besoin d'une image Docker
        ↓
L'image Docker doit être dans ECR
        ↓
Mais ECR est encore vide
```

On utilise donc une image initiale :

```text
ecr-bassirou:bootstrap
```

Puis, une fois l'infrastructure créée, le pipeline CI/CD prend le relais avec des images taguées avec le SHA Git.

---

# 4. Ordre de déploiement

Le déploiement doit respecter cet ordre :

```text
1. Terraform Bootstrap
        ↓
2. ECR
        ↓
3. Image Docker :bootstrap
        ↓
4. Terraform infrastructure
        ↓
5. ECS / ALB / RDS / VPC
        ↓
6. Mise à jour des secrets réseau GitHub
        ↓
7. Pipeline Django
        ↓
8. Image Docker avec SHA Git
        ↓
9. Déploiement ECS
        ↓
10. Migration Django
```

Cet ordre est important à cause des dépendances entre les composants.

---

# 5. Prérequis

Avant de commencer, il faut disposer de :

* AWS CLI
* Docker
* Terraform
* Git
* un compte AWS
* un repository GitHub
* les droits nécessaires dans AWS

Vérifier les outils :

```powershell
aws --version
docker --version
terraform version
git --version
```

Vérifier également l'identité AWS :

```powershell
aws sts get-caller-identity
```

---

# 6. Région AWS

Le projet utilise :

```text
eu-west-3
```

soit la région Paris.

Les commandes Docker/ECR et les workflows GitHub Actions doivent utiliser la même région.

---

# 7. Étape 1 — Terraform Bootstrap

Le premier bootstrap se trouve dans :

```text
infrastructure/bootstrap/
```

Il prépare les ressources nécessaires au fonctionnement de Terraform et GitHub Actions.

---

## 7.1 Initialiser Terraform

Depuis la racine du projet :

```powershell
cd infrastructure/bootstrap
```

Puis :

```powershell
terraform init
```

Vérifier la configuration :

```powershell
terraform validate
```

Puis :

```powershell
terraform plan
```

Et appliquer :

```powershell
terraform apply
```

---

# 8. Ressources créées par le Bootstrap

Le bootstrap crée notamment :

## Bucket S3 Terraform

Le state Terraform est stocké dans un bucket S3.

Exemple :

```text
terraform-state-bassirou-2026
```

Le S3 permet d'avoir un state centralisé au lieu de conserver le state uniquement sur la machine locale.

---

## GitHub OIDC

GitHub Actions ne doit pas avoir besoin d'une clé AWS statique du type :

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

À la place :

```text
GitHub Actions
      ↓
OIDC
      ↓
AWS IAM
      ↓
Role GitHub Actions
      ↓
AWS
```

Cela permet à GitHub Actions d'assumer un rôle IAM temporairement.

Le rôle créé est par exemple :

```text
github-actions-role
```

---

# 9. Étape 2 — ECR

L'ECR est le registre Docker utilisé par ECS.

Le repository est :

```text
ecr-bassirou
```

Son URL est de la forme :

```text
715133784874.dkr.ecr.eu-west-3.amazonaws.com/ecr-bassirou
```

Le repository utilise :

* scan des images
* tags immuables
* lifecycle policy
* conservation des dernières images

---

# 10. Créer le repository ECR avec Terraform

Le code se trouve dans :

```text
infrastructure/shared/ecr/
```

Initialiser :

```powershell
cd infrastructure/shared/ecr

terraform init
terraform validate
terraform plan
terraform apply
```

À la fin, Terraform retourne notamment :

```text
repository_arn
repository_url
```

---

# 11. Connexion Docker à ECR

Avant de pousser une image Docker, il faut authentifier Docker auprès d'ECR.

Depuis PowerShell :

```powershell
aws ecr get-login-password --region eu-west-3 |
docker login --username AWS --password-stdin 715133784874.dkr.ecr.eu-west-3.amazonaws.com
```

Si tout fonctionne :

```text
Login Succeeded
```

---

# 12. Étape 3 — Construire l'image Docker Bootstrap

Le Dockerfile se trouve dans :

```text
app/Dockerfile
```

Il utilise notamment :

```dockerfile
FROM python:3.11-slim
```

L'application utilise Gunicorn pour servir Django.

Le `Dockerfile` installe les dépendances puis copie l'application.

L'image expose :

```text
8000
```

---

# 13. Entrypoint Django

Le fichier :

```text
app/entrypoint.sh
```

contient :

```sh
exec gunicorn --bind 0.0.0.0:8000 crud.wsgi:application
```

Gunicorn écoute donc sur :

```text
0.0.0.0:8000
```

C'est important car le conteneur ECS doit être accessible par le Load Balancer.

---

# 14. Construire l'image Bootstrap

Depuis la racine :

```powershell
docker build `
  -t 715133784874.dkr.ecr.eu-west-3.amazonaws.com/ecr-bassirou:bootstrap `
  ./app
```

Vérifier :

```powershell
docker images
```

---

# 15. Tester l'image localement

Avant de pousser l'image, il est recommandé de la tester localement.

Exemple :

```powershell
docker run --rm -p 8000:8000 `
  715133784874.dkr.ecr.eu-west-3.amazonaws.com/ecr-bassirou:bootstrap
```

L'application doit démarrer avec Gunicorn.

Le health check utilisé par ECS est :

```text
/health/
```

Tester :

```text
http://localhost:8000/health/
```

---

# 16. Pousser l'image Bootstrap dans ECR

Une fois l'image validée :

```powershell
docker push 715133784874.dkr.ecr.eu-west-3.amazonaws.com/ecr-bassirou:bootstrap
```

On obtient alors :

```text
ECR
└── ecr-bassirou
    └── bootstrap
```

Cette image permet maintenant à ECS d'être créé.

---

# 17. Pourquoi utiliser `bootstrap` et non `latest` ?

Il est préférable de ne pas utiliser :

```text
latest
```

dans ECS.

Le pipeline utilise à la place le SHA Git :

```text
ecr-bassirou:<github.sha>
```

Exemple :

```text
ecr-bassirou:a83f72c9...
```

Cela permet de savoir exactement quelle version du code est déployée.

```text
Git commit
    ↓
SHA
    ↓
Docker tag
    ↓
ECS
```

On peut donc relier :

```text
Code Git
   ↕
Image Docker
   ↕
Déploiement ECS
```

---

# 18. Étape 4 — Infrastructure AWS

Les environnements sont :

```text
infrastructure/environments/dev/
infrastructure/environments/staging/
infrastructure/environments/prod/
```

Chaque environnement utilise les modules Terraform :

```text
VPC
ECR
Security
ALB
ECS
RDS
```

---

# 19. Architecture réseau

L'architecture réseau finale est :

```text
                    Internet
                       │
                       ▼
              ┌─────────────────┐
              │       ALB       │
              │ Public Subnets  │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │   ECS Fargate   │
              │ Private Subnets│
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │   RDS PostgreSQL│
              │ Private Subnets│
              └─────────────────┘
```

ECS et RDS ne sont donc pas directement exposés à Internet.

---

# 20. Pourquoi ECS est dans des subnets privés ?

ECS n'a pas besoin d'être directement accessible depuis Internet.

Seul l'ALB doit être public.

Le principe est :

```text
Internet
   ↓
ALB public
   ↓
ECS privé
   ↓
RDS privé
```

Cela réduit la surface d'exposition du système.

Dans Terraform :

```hcl
subnet_ids = module.vpc.private_subnet_ids
```

L'ALB utilise quant à lui :

```hcl
subnet_ids = module.vpc.public_subnet_ids
```

---

# 21. Security Groups

Le trafic est également contrôlé avec les Security Groups.

Le principe est :

```text
Internet
   ↓
ALB : 80/443
   ↓
ECS : 8000
   ↓
RDS : 5432
```

Le Security Group ECS doit principalement accepter le trafic applicatif provenant de l'ALB.

RDS doit accepter PostgreSQL depuis ECS.

---

# 22. Étape 5 — Déploiement Terraform avec GitHub Actions

L'infrastructure des environnements est déployée via :

```text
.github/workflows/terraform.yml
```

L'objectif est de ne pas effectuer le déploiement de `dev`, `staging` ou `prod` manuellement depuis le poste local.

Le pipeline utilise :

```text
GitHub Actions
       ↓
OIDC
       ↓
IAM Role
       ↓
Terraform
       ↓
AWS
```

---

# 23. Lancer le workflow Terraform

Dans GitHub :

```text
Actions
   ↓
terraform CI/CD
   ↓
Run workflow
```

Choisir :

```text
action: apply
environment: dev
```

Puis lancer le workflow.

Le pipeline va notamment :

1. récupérer le code
2. installer Terraform
3. s'authentifier auprès d'AWS
4. initialiser Terraform
5. utiliser le backend S3
6. utiliser l'image `bootstrap`
7. créer l'infrastructure

---

# 24. Pourquoi Terraform utilise `image_tag=bootstrap` ?

Lors du premier déploiement, aucune image SHA issue du pipeline Django n'existe encore.

Terraform utilise donc :

```text
image_tag=bootstrap
```

ECS peut alors être créé avec :

```text
ecr-bassirou:bootstrap
```

Une fois l'infrastructure disponible, le pipeline Django pourra déployer :

```text
ecr-bassirou:<SHA>
```

---

# 25. Résultat attendu du déploiement Terraform

À la fin, Terraform doit avoir créé notamment :

```text
VPC
├── Public Subnets
│   └── ALB
│
└── Private Subnets
    ├── ECS
    └── RDS
```

Les outputs Terraform donnent notamment :

```text
vpc_id
private_subnet_ids
public_subnet_ids
ecs_sg_id
rds_endpoint
load_balancer_url
```

---

# 26. Vérifier l'ALB

L'output :

```text
load_balancer_url
```

ressemble à :

```text
http://alb-bassirou-dev-XXXXXXXX.eu-west-3.elb.amazonaws.com
```

L'ALB reçoit les requêtes HTTP et les transmet à ECS.

Le flux devient :

```text
Client
  ↓
ALB
  ↓
Target Group
  ↓
ECS Task
  ↓
Gunicorn
  ↓
Django
```

---

# 27. Health Check ECS

Le conteneur possède un health check :

```text
GET /health/
```

ECS vérifie :

```text
http://localhost:8000/health/
```

La configuration utilise notamment :

```text
interval = 30 secondes
timeout = 5 secondes
retries = 3
startPeriod = 60 secondes
```

Cela laisse le temps à Django et Gunicorn de démarrer.

---

# 28. Tester l'application

Une fois ECS lancé, vérifier l'URL de l'ALB :

```text
http://<load-balancer-url>/
```

Puis :

```text
http://<load-balancer-url>/health/
```

Le endpoint `/health/` doit répondre correctement.

---

# 29. Attention aux IDs des subnets

C'est un point important avec cette architecture.

Après un :

```text
terraform destroy
```

puis un nouveau :

```text
terraform apply
```

AWS peut créer de nouveaux :

```text
subnet IDs
security group IDs
VPC IDs
```

Par exemple :

```text
subnet-xxxxxxxx
```

peut devenir :

```text
subnet-yyyyyyyy
```

Les anciens IDs deviennent alors invalides.

---

# 30. Secrets GitHub nécessaires

Les workflows utilisent des secrets spécifiques à chaque environnement.

Exemple pour DEV :

```text
DB_PASSWORD
DJANGO_SECRET_KEY
AWS_ROLE_ARN
SUBNET_IDS_DEV
ECS_SG_DEV
```

Pour staging :

```text
DB_PASSWORD
DJANGO_SECRET_KEY
AWS_ROLE_ARN
SUBNET_IDS_STAGING
ECS_SG_STAGING
```

Pour prod :

```text
DB_PASSWORD
DJANGO_SECRET_KEY
AWS_ROLE_ARN
SUBNET_IDS_PROD
ECS_SG_PROD
```

Selon la configuration du repository, les secrets peuvent être placés dans les GitHub Environments :

```text
dev
staging
prod
```

---

# 31. Pourquoi `SUBNET_IDS_*` et `ECS_SG_*` sont nécessaires ?

Les migrations Django sont exécutées dans une tâche ECS temporaire.

Cette tâche doit être lancée dans le même réseau privé que l'application.

Elle utilise donc :

```text
subnets privés
+
Security Group ECS
```

La commande ECS utilise :

```text
assignPublicIp=DISABLED
```

La migration reste donc dans le réseau privé.

---

# 32. Mettre à jour les secrets après recréation de l'infrastructure

Après un nouveau déploiement Terraform, récupérer les nouveaux outputs.

Par exemple :

```text
private_subnet_ids
ecs_sg_id
```

Puis mettre à jour :

```text
SUBNET_IDS_DEV
ECS_SG_DEV
```

dans GitHub.

Il ne faut jamais reprendre automatiquement les anciens IDs d'un ancien déploiement.

---

# 33. Étape 6 — Pipeline Django

Le pipeline applicatif est :

```text
.github/workflows/django.yml
```

Il prend en charge :

```text
Tests
  ↓
Build Docker
  ↓
Push ECR
  ↓
Terraform ECS
  ↓
Migration Django
```

---

# 34. Déclenchement du pipeline Django

Le workflow se déclenche notamment lors d'un push sur `main` avec des modifications dans :

```text
app/**
```

Il peut également être lancé manuellement pour staging/prod.

---

# 35. Étape 1 du pipeline : tests

GitHub Actions démarre notamment PostgreSQL pour exécuter les tests Django.

Le pipeline :

```text
Checkout
   ↓
Python
   ↓
Dependencies
   ↓
PostgreSQL
   ↓
Django tests
```

Il peut également exécuter :

```text
collectstatic
```

Si les tests échouent :

```text
❌ Pipeline arrêté
```

L'image Docker ne doit pas être déployée.

---

# 36. Étape 2 : build Docker

Si les tests passent :

```text
docker build
```

L'image est construite à partir de :

```text
app/Dockerfile
```

---

# 37. Tag Docker avec le SHA Git

Le tag utilisé est :

```text
${{ github.sha }}
```

Exemple :

```text
ecr-bassirou:a91f52d7...
```

Cela garantit une correspondance claire entre le code et l'image.

---

# 38. Push vers ECR

Le pipeline pousse ensuite :

```text
ecr-bassirou:<github.sha>
```

dans :

```text
Amazon ECR
```

On obtient par exemple :

```text
ECR
└── ecr-bassirou
    ├── bootstrap
    ├── a91f52d...
    ├── b82e63e...
    └── c73f74f...
```

---

# 39. Étape 3 : déploiement ECS

Terraform reçoit le SHA :

```text
image_tag=<github.sha>
```

Terraform met alors à jour la Task Definition ECS :

```text
ancienne image
    ↓
ecr-bassirou:bootstrap

nouvelle image
    ↓
ecr-bassirou:<github.sha>
```

ECS lance ensuite une nouvelle task avec cette image.

---

# 40. Déploiement progressif d'une nouvelle version

Le fonctionnement est :

```text
Git push
   ↓
Tests
   ↓
Docker build
   ↓
Docker push
   ↓
Terraform
   ↓
Nouvelle Task Definition
   ↓
ECS démarre une nouvelle task
   ↓
Health Check
   ↓
ALB envoie le trafic vers la nouvelle task
```

L'ancienne task peut ensuite être arrêtée par ECS.

---

# 41. Étape 4 : migration Django

Après le déploiement ECS, le workflow lance une tâche ECS temporaire pour :

```bash
python manage.py migrate
```

La tâche utilise :

```text
ECS private subnets
+
ECS Security Group
+
assignPublicIp=DISABLED
```

Elle peut donc accéder à RDS PostgreSQL via le réseau privé.

---

# 42. Flux complet d'un déploiement DEV

Un push sur `main` peut donc déclencher :

```text
GitHub
   │
   ▼
Tests Django
   │
   ├── ❌ échec → stop
   │
   ▼
Docker Build
   │
   ▼
ECR
   │
   ▼
Terraform
   │
   ▼
ECS
   │
   ▼
Nouvelle Task
   │
   ▼
Health Check
   │
   ▼
Migration Django
   │
   ▼
Application disponible
```

---

# 43. Staging

Staging suit le même principe que DEV.

La différence est que l'environnement Terraform est :

```text
infrastructure/environments/staging/
```

et que les secrets sont ceux de :

```text
staging
```

Le workflow peut être lancé manuellement avec :

```text
environment: staging
```

et :

```text
image_tag: <SHA>
```

---

# 44. Promotion vers Staging

Une image déjà construite peut être promue vers staging.

Exemple :

```text
main
 ↓
SHA abc123
 ↓
ECR
 ↓
DEV
```

Puis :

```text
SHA abc123
 ↓
STAGING
```

Il n'est donc pas nécessaire de reconstruire une image différente pour staging.

On déploie exactement la même image.

---

# 45. Production

Production utilise :

```text
infrastructure/environments/prod/
```

et les secrets :

```text
prod
```

Le déploiement est manuel dans le workflow.

On sélectionne :

```text
environment: prod
```

et le SHA Docker à déployer.

---

# 46. Pourquoi utiliser le même SHA ?

Supposons :

```text
Git commit:
abc123
```

Le pipeline crée :

```text
ecr-bassirou:abc123
```

Cette même image peut être utilisée pour :

```text
DEV
STAGING
PROD
```

Le principe est :

```text
Build once
Deploy multiple times
```

Cela évite qu'une image différente soit reconstruite entre les environnements.

---

# 47. Cycle complet du projet

Le cycle normal devient :

```text
Développeur
    │
    ▼
Git commit
    │
    ▼
GitHub
    │
    ▼
Tests
    │
    ▼
Docker Build
    │
    ▼
ECR : SHA
    │
    ▼
Terraform
    │
    ▼
ECS
    │
    ▼
Migration
    │
    ▼
Application
```

Puis :

```text
DEV
 ↓
STAGING
 ↓
PROD
```

---

# 48. Responsabilités de chaque composant

## Terraform

Terraform gère l'infrastructure :

```text
VPC
Subnets
Security Groups
ALB
ECS
RDS
IAM
ECR
```

---

## Docker

Docker empaquette l'application :

```text
Django
+
Python
+
Dependencies
+
Gunicorn
```

---

## ECR

ECR stocke les images :

```text
bootstrap
SHA Git
```

---

## ECS

ECS exécute les conteneurs.

---

## ALB

L'ALB reçoit le trafic HTTP et le transmet aux tasks ECS.

---

## RDS

RDS héberge PostgreSQL.

---

## GitHub Actions

GitHub Actions orchestre :

```text
Tests
Build
Push
Terraform
Migration
```

---

# 49. Terraform Bootstrap vs CI/CD

Il faut bien distinguer les deux phases.

| Élément           | Bootstrap        | CI/CD       |
| ----------------- | ---------------- | ----------- |
| Terraform S3      | Oui              | Utilisé     |
| GitHub OIDC       | Oui              | Utilisé     |
| IAM Role          | Oui              | Utilisé     |
| ECR               | Oui              | Utilisé     |
| Image `bootstrap` | Oui              | Non         |
| Image SHA         | Non              | Oui         |
| Tests Django      | Non              | Oui         |
| Docker Build      | Bootstrap manuel | Oui         |
| ECS               | Préparation      | Déploiement |
| Migration         | Non              | Oui         |

---

# 50. Que se passe-t-il si ECR est supprimé ?

Si le repository ECR est supprimé, l'infrastructure ne peut plus récupérer :

```text
ecr-bassirou:bootstrap
```

Il faut alors recréer ECR :

```text
Terraform ECR
      ↓
docker login
      ↓
docker build
      ↓
docker push :bootstrap
      ↓
Terraform ECS
```

Il faut donc toujours reconstruire l'image Bootstrap après une recréation complète d'ECR.

---

# 51. Que se passe-t-il après un `terraform destroy` ?

Un `destroy` supprime les ressources AWS.

Après un nouveau déploiement :

```text
terraform apply
```

de nouvelles ressources peuvent être créées.

Il faut alors vérifier :

```text
VPC ID
Subnet IDs
Security Group IDs
RDS endpoint
ALB URL
```

Puis mettre à jour les secrets GitHub qui dépendent de ces ressources.

En particulier :

```text
SUBNET_IDS_DEV
ECS_SG_DEV
```

ou les équivalents staging/prod.

---

# 52. Vérifications AWS après déploiement

Après Terraform, vérifier :

```text
VPC
├── Public Subnets
├── Private Subnets
├── Route Tables
└── Security Groups
```

Puis :

```text
ALB
├── Listener
├── Target Group
└── Targets
```

Puis :

```text
ECS Cluster
└── Service
    └── Task
```

Puis :

```text
RDS
└── PostgreSQL
```

---

# 53. Vérifier ECS

Dans AWS ECS, vérifier :

```text
Cluster
    ↓
Service
    ↓
Running tasks
```

La task doit être :

```text
RUNNING
```

et son health status doit être correct.

---

# 54. Vérifier les logs

Les logs ECS sont envoyés vers CloudWatch.

Le groupe de logs est de la forme :

```text
/ecs/django-bassirou-dev
```

On doit retrouver des logs similaires à :

```text
Starting gunicorn
Listening at: http://0.0.0.0:8000
Booting worker
```

---

# 55. Vérifier le health check

Tester :

```text
http://<ALB_URL>/health/
```

Le endpoint doit répondre.

Si le Target Group indique :

```text
unhealthy
```

il faut vérifier :

1. ECS task
2. port 8000
3. Security Groups
4. health check
5. Gunicorn
6. logs CloudWatch
7. configuration Django
8. ALB Target Group

---

# 56. Erreurs fréquentes

## ECR vide

Erreur :

```text
CannotPullContainerError
```

Cause possible :

```text
l'image bootstrap n'existe pas
```

Solution :

```text
docker push :bootstrap
```

---

## Mauvais subnet ID

Erreur :

```text
The subnet ID ... does not exist
```

Cause :

```text
les IDs GitHub sont anciens
```

Solution :

```text
Terraform outputs
       ↓
nouveaux subnet IDs
       ↓
GitHub Secrets
```

---

## ECS ne démarre pas

Vérifier :

```text
CloudWatch
ECS task events
ECR image
Security Groups
subnets
IAM execution role
```

---

## Target Group unhealthy

Vérifier :

```text
/health/
```

et :

```text
containerPort = 8000
```

ainsi que les Security Groups.

---

## Migration impossible

Vérifier :

```text
SUBNET_IDS_*
ECS_SG_*
assignPublicIp=DISABLED
RDS Security Group
DB_HOST
DB_PORT
DB_USER
DB_PASSWORD
DB_NAME
```

---

# 57. Checklist complète de premier déploiement

## AWS Bootstrap

```text
[ ] AWS CLI fonctionne
[ ] Terraform fonctionne
[ ] Docker fonctionne
[ ] Git fonctionne
[ ] Terraform bootstrap appliqué
[ ] S3 state créé
[ ] GitHub OIDC créé
[ ] IAM Role créé
```

## ECR

```text
[ ] ECR créé
[ ] Docker connecté à ECR
[ ] Image bootstrap construite
[ ] Image bootstrap testée
[ ] Image bootstrap poussée
```

## Infrastructure

```text
[ ] VPC créé
[ ] Public subnets créés
[ ] Private subnets créés
[ ] ALB créé
[ ] ECS créé
[ ] RDS créé
[ ] Security Groups créés
[ ] ECS task RUNNING
[ ] Target Group healthy
```

## GitHub

```text
[ ] AWS_ROLE_ARN configuré
[ ] DB_PASSWORD configuré
[ ] DJANGO_SECRET_KEY configuré
[ ] SUBNET_IDS_DEV configuré
[ ] ECS_SG_DEV configuré
```

## Application

```text
[ ] Tests Django OK
[ ] Docker build OK
[ ] Image SHA poussée dans ECR
[ ] ECS déployé
[ ] Migration exécutée
[ ] /health/ OK
[ ] Application accessible via ALB
```

---

# 58. Checklist staging

```text
[ ] Infrastructure staging créée
[ ] RDS staging OK
[ ] ECS staging OK
[ ] ALB staging OK
[ ] SUBNET_IDS_STAGING à jour
[ ] ECS_SG_STAGING à jour
[ ] Image SHA sélectionnée
[ ] Terraform staging OK
[ ] Migration staging OK
[ ] Health check OK
```

---

# 59. Checklist production

```text
[ ] Infrastructure prod créée
[ ] RDS prod OK
[ ] ECS prod OK
[ ] ALB prod OK
[ ] SUBNET_IDS_PROD à jour
[ ] ECS_SG_PROD à jour
[ ] SHA validé
[ ] Terraform prod OK
[ ] Migration prod OK
[ ] Health check OK
```

---

# 60. Vue d'ensemble finale

Le projet fonctionne finalement comme ceci :

```text
                         GITHUB
                           │
                           │
             ┌─────────────┴─────────────┐
             │                           │
             ▼                           ▼
       terraform.yml                django.yml
             │                           │
             ▼                           ▼
        Terraform                    Tests Django
             │                           │
             │                           ▼
             │                       Docker Build
             │                           │
             │                           ▼
             │                          ECR
             │                           │
             │                           ▼
             │                       Image SHA
             │                           │
             └─────────────┬─────────────┘
                           │
                           ▼
                         AWS
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
             ALB          ECS          RDS
           public        private       private
              │            │            │
              └───────┬────┘            │
                      │                 │
                      └─────────────────┘
                              │
                           PostgreSQL
```

---

# 61. Principe à retenir

Le projet repose sur quatre idées principales :

### 1. Terraform crée l'infrastructure

```text
Infrastructure as Code
```

Tout ce qui concerne AWS est décrit dans Terraform.

### 2. Docker empaquette l'application

```text
Code Django
    ↓
Docker Image
```

### 3. ECR versionne les images

```text
bootstrap
SHA Git
```

Chaque version du code peut être identifiée précisément.

### 4. GitHub Actions automatise le déploiement

```text
Git push
   ↓
Tests
   ↓
Build
   ↓
ECR
   ↓
Terraform
   ↓
ECS
   ↓
Migration
```

---

# 62. Résumé du premier déploiement

Pour un premier déploiement complet :

```text
1. Terraform bootstrap
        ↓
2. Création ECR
        ↓
3. Docker login
        ↓
4. Build :bootstrap
        ↓
5. Push :bootstrap
        ↓
6. GitHub Actions
        ↓
7. terraform apply / dev
        ↓
8. VPC + ALB + ECS + RDS
        ↓
9. Récupération des nouveaux IDs
        ↓
10. Mise à jour des secrets GitHub
        ↓
11. Push du code Django
        ↓
12. Tests
        ↓
13. Docker build
        ↓
14. Push SHA dans ECR
        ↓
15. Terraform ECS
        ↓
16. Migration
        ↓
17. Health check
        ↓
18. Application disponible
```

---

# 63. Résumé du fonctionnement quotidien

Une fois l'infrastructure initialisée, le développeur n'a normalement plus besoin de reconstruire manuellement l'image `bootstrap`.

Le fonctionnement quotidien devient simplement :

```text
Développeur
    ↓
git push
    ↓
GitHub Actions
    ↓
Tests
    ↓
Docker image SHA
    ↓
ECR
    ↓
ECS
    ↓
Migration
```

Le `bootstrap` est principalement nécessaire lors de l'initialisation ou lorsqu'ECR est recréé.

---

# 64. Règle finale

La règle à retenir pour comprendre tout le projet est :

```text
BOOTSTRAP
    ↓
préparer AWS + ECR + image initiale
    ↓
TERRAFORM
    ↓
créer l'infrastructure
    ↓
CI/CD
    ↓
construire et déployer les vraies versions
```

Et côté réseau :

```text
Internet
   ↓
ALB public
   ↓
ECS privé
   ↓
RDS privé
```

C'est cette séparation qui permet d'avoir une architecture claire :

```text
Infrastructure
     +
Containerisation
     +
Registry Docker
     +
CI/CD
     +
Réseau privé
     +
Déploiement versionné
```

Le résultat final est une chaîne de déploiement reproductible :

```text
Git
 ↓
GitHub Actions
 ↓
Docker
 ↓
ECR
 ↓
Terraform
 ↓
ECS Fargate
 ↓
ALB
 ↓
Django
 ↓
RDS PostgreSQL
```