# 🔐 OIDC entre GitHub Actions et AWS

Permettre à **GitHub Actions d'assumer un rôle IAM AWS sans utiliser de clés AWS statiques**, grâce à **OpenID Connect (OIDC)**.

L'objectif est de permettre à un workflow GitHub Actions d'obtenir des **credentials AWS temporaires** via AWS STS, sans stocker de `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` dans les secrets GitHub.

---

# Comment ça fonctionne ?

Le principe est le suivant :

```text
┌──────────────────────┐
│   GitHub Actions     │
│                      │
│   Workflow           │
└──────────┬───────────┘
           │
           │ OIDC JWT
           ▼
┌──────────────────────────────┐
│ GitHub OIDC Provider         │
│                              │
│ token.actions.githubusercontent.com
└──────────┬───────────────────┘
           │
           │ sts:AssumeRoleWithWebIdentity
           ▼
┌──────────────────────────────┐
│ AWS IAM                      │
│                              │
│ Trust Policy                 │
│ + OIDC Identity Provider     │
└──────────┬───────────────────┘
           │
           ▼
┌──────────────────────────────┐
│ AWS STS                      │
│                              │
│ Credentials temporaires      │
└──────────┬───────────────────┘
           │
           ▼
┌──────────────────────────────┐
│ Ressources AWS               │
│ EC2 / ECS / ECR / RDS / S3   │
└──────────────────────────────┘
```

GitHub génère un token OIDC pour le workflow.

AWS vérifie ce token grâce au provider OIDC et contrôle notamment les claims :

* `aud` → l'audience du token ;
* `sub` → le contexte GitHub autorisé.

Si les conditions de la Trust Policy sont respectées, AWS STS autorise :

```text
sts:AssumeRoleWithWebIdentity
```

et fournit des credentials AWS temporaires au workflow.

---

# ⚠️ Deux formats de `sub`

Le claim `sub` (*subject*) est particulièrement important dans la Trust Policy AWS.

Depuis le **15 juillet 2026**, GitHub utilise un nouveau format basé sur des identifiants immuables pour les repositories concernés.

## 🟠 Ancien format

Le format historique est :

```text
repo:OWNER/REPO:...
```

Par exemple :

```text
repo:octo-org/octo-repo:ref:refs/heads/main
```

Les repositories créés **avant le 15 juillet 2026** peuvent continuer à utiliser ce format tant qu'ils n'ont pas opté pour le nouveau format immutable.

---

## 🔵 Nouveau format immutable

Le nouveau format contient l'ID du propriétaire et l'ID du repository :

```text
repo:OWNER@OWNER_ID/REPO@REPO_ID:...
```

Par exemple :

```text
repo:octo-org@123456/octo-repo@456789:ref:refs/heads/main
```

Les repositories créés **à partir du 15 juillet 2026** utilisent ce nouveau format.

Les repositories plus anciens peuvent également passer à ce format via l'opt-in prévu par GitHub.

---

## Résumé

| Situation                                    | Format du `sub`                        |
| -------------------------------------------- | -------------------------------------- |
| Repository créé avant le 15/07/2026          | `repo:OWNER/REPO:...`                  |
| Repository créé avant le 15/07/2026 + opt-in | `repo:OWNER@OWNER_ID/REPO@REPO_ID:...` |
| Repository créé à partir du 15/07/2026       | `repo:OWNER@OWNER_ID/REPO@REPO_ID:...` |

> 💡 **Important :** ne devine pas le format utilisé par ton repository. En cas de doute, vérifie le `sub` réellement émis par GitHub Actions et utilise exactement cette valeur dans ta Trust Policy AWS.

---

# Exemple Terraform complet

Dans cet exemple, le repository utilise le **nouveau format immutable**.

Repository :

```text
cisse17/django-ecs-devops
```

IDs :

```text
OWNER_ID = 119404406
REPO_ID  = 1374481008
```

Le `sub` utilisé est donc :

```text
repo:cisse17@119404406/django-ecs-devops@1374481008:*
```

---

# 1️⃣ OIDC Provider

AWS doit faire confiance aux tokens OIDC émis par GitHub.

```hcl
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
```

Le `client_id_list` contient :

```text
sts.amazonaws.com
```

C'est l'audience (`aud`) utilisée pour AWS.

---

# 2️⃣ IAM Role

Le rôle IAM définit **qui peut l'assumer**.

```hcl
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
            # SEULEMENT mon repository GitHub peut utiliser ce rôle
            #
            # Nouveau format immutable subject :
            # repo:OWNER@OWNER_ID/REPO@REPO_ID:*
            "token.actions.githubusercontent.com:sub" = [
              "repo:cisse17@119404406/django-ecs-devops@1374481008:*"
            ]
          }

          StringEquals = {
            # L'audience doit être sts.amazonaws.com
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
```

---

## Que garantit cette Trust Policy ?

Cette condition :

```hcl
"token.actions.githubusercontent.com:sub" = [
  "repo:cisse17@119404406/django-ecs-devops@1374481008:*"
]
```

limite l'utilisation du rôle au repository :

```text
cisse17/django-ecs-devops
```

avec :

```text
OWNER_ID = 119404406
REPO_ID  = 1374481008
```

Le `:*` à la fin permet différents contextes de ce repository.

Par exemple :

```text
repo:cisse17@119404406/django-ecs-devops@1374481008:ref:refs/heads/main
```

ou :

```text
repo:cisse17@119404406/django-ecs-devops@1374481008:environment:production
```

---

# Restreindre à une branche précise

Si tu veux autoriser uniquement la branche `main`, tu peux utiliser `StringEquals` :

```hcl
Condition = {
  StringEquals = {
    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"

    "token.actions.githubusercontent.com:sub" = "repo:cisse17@119404406/django-ecs-devops@1374481008:ref:refs/heads/main"
  }
}
```

Cette approche est plus restrictive que :

```text
repo:cisse17@119404406/django-ecs-devops@1374481008:*
```

---

# 3️⃣ IAM Policy

La Trust Policy détermine **qui peut assumer le rôle**.

La IAM Policy détermine ensuite **ce que ce rôle peut faire sur AWS**.

Dans cet exemple :

```hcl
# IAM POLICY — permissions accordées à GitHub Actions

resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          # EC2
          "ec2:*",

          # RDS
          "rds:*",

          # VPC
          "vpc:*",

          # Application Load Balancer
          "elasticloadbalancing:*",

          # S3 — notamment pour le Terraform remote state
          "s3:*",

          # IAM — si Terraform doit créer/modifier des ressources IAM
          "iam:*",

          # ECR
          "ecr:*",

          # ECS
          "ecs:*",

          # CloudWatch Logs
          "logs:*",

          # Secrets Manager
          "secretsmanager:*"
        ]

        Resource = "*"
      }
    ]
  })
}
```

---

## ⚠️ Attention au `iam:*`

Dans cet exemple :

```hcl
"iam:*"
```

donne des permissions IAM très larges.

De même :

```hcl
Resource = "*"
```

autorise les actions sur toutes les ressources correspondant aux permissions accordées.

C'est acceptable pour un **POC, un laboratoire ou un exemple pédagogique**, mais ce n'est pas une configuration **least privilege**.

Pour un environnement de production, il est préférable de :

* limiter les actions IAM ;
* limiter les ressources accessibles ;
* séparer les rôles selon les besoins ;
* éviter `iam:*` lorsque Terraform n'en a pas réellement besoin.

---

# 4️⃣ Le workflow GitHub Actions

Une fois le provider OIDC et le rôle IAM créés, GitHub Actions peut assumer le rôle.

```yaml
name: Test OIDC

on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: arn:aws:iam::ACCOUNT_ID:role/github-actions-role
          aws-region: eu-west-3
          audience: sts.amazonaws.com

      - name: Check AWS identity
        run: aws sts get-caller-identity
```

La permission :

```yaml
permissions:
  id-token: write
```

est indispensable pour permettre au workflow de demander un token OIDC à GitHub.

---

# 5️⃣ Le flow complet

Avec cette configuration :

```text
GitHub Actions
      │
      │ id-token: write
      ▼
GitHub OIDC
      │
      │ JWT
      │
      │ aud = sts.amazonaws.com
      │
      │ sub =
      │ repo:cisse17@119404406/
      │ django-ecs-devops@1374481008:...
      ▼
AWS OIDC Provider
      │
      ▼
IAM Trust Policy
      │
      │ vérifie aud + sub
      ▼
AWS STS
      │
      │ Temporary Credentials
      ▼
IAM Role
      │
      ▼
EC2 / ECS / ECR / RDS / S3 / etc.
```

---

# 6️⃣ Récupérer les IDs du repository

Si tu dois récupérer les IDs utilisés dans le nouveau format :

```bash
gh api repos/OWNER/REPO \
  --jq '{owner_id: .owner.id, repo_id: .id}'
```

Exemple :

```json
{
  "owner_id": 119404406,
  "repo_id": 1374481008
}
```

Tu peux alors construire :

```text
repo:OWNER@OWNER_ID/REPO@REPO_ID:...
```

Dans notre cas :

```text
repo:cisse17@119404406/django-ecs-devops@1374481008:...
```

---

# 7️⃣ Vérifier le `sub` réellement émis

En cas de doute, tu peux inspecter le JWT OIDC depuis GitHub Actions :

```yaml
- name: Debug OIDC token
  run: |
    TOKEN=$(curl -s \
      -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
      "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.amazonaws.com" \
      | jq -r '.value')

    echo "$TOKEN" \
      | cut -d. -f2 \
      | base64 -d 2>/dev/null \
      | jq .sub
```

Tu peux obtenir par exemple :

### Ancien format

```text
"repo:OWNER/REPO:ref:refs/heads/main"
```

### Nouveau format

```text
"repo:OWNER@OWNER_ID/REPO@REPO_ID:ref:refs/heads/main"
```

> ⚠️ Le token OIDC est temporaire, mais il contient des informations de contexte. Évite de l'afficher intégralement dans les logs.

---

# 8️⃣ GitHub Environments

Si ton workflow utilise un **GitHub Environment**, le `sub` peut avoir une structure différente.

Ancien format :

```text
repo:OWNER/REPO:environment:production
```

Nouveau format :

```text
repo:OWNER@OWNER_ID/REPO@REPO_ID:environment:production
```

Il faut donc adapter la Trust Policy au `sub` réellement émis.

---

# 9️⃣ Appliquer Terraform

Après avoir modifié la configuration :

```bash
terraform plan
```

Puis :

```bash
terraform apply
```

---

# 10️⃣ Vérifier côté AWS

Vérifier les providers OIDC :

```bash
aws iam list-open-id-connect-providers
```

Puis vérifier le rôle :

```bash
aws iam get-role \
  --role-name github-actions-role \
  --query "Role.AssumeRolePolicyDocument" \
  --output json
```

Tu dois notamment retrouver :

```text
token.actions.githubusercontent.com:aud
```

avec :

```text
sts.amazonaws.com
```

et :

```text
token.actions.githubusercontent.com:sub
```

avec ton `sub` :

```text
repo:cisse17@119404406/django-ecs-devops@1374481008:*
```

---

# 11️⃣ Tester l'accès AWS

Depuis GitHub Actions :

```yaml
- name: Check AWS identity
  run: aws sts get-caller-identity
```

Si OIDC fonctionne, AWS doit retourner l'identité du rôle assumé.

Tu peux obtenir quelque chose comme :

```json
{
  "UserId": "AROA...",
  "Account": "123456789012",
  "Arn": "arn:aws:sts::123456789012:assumed-role/github-actions-role/..."
}
```

---

# 12️⃣ Troubleshooting

Si GitHub Actions retourne :

```text
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

vérifie les éléments suivants.

## 1. Permission OIDC

Le workflow doit avoir :

```yaml
permissions:
  id-token: write
```

---

## 2. Audience

Le token doit utiliser :

```text
aud = sts.amazonaws.com
```

Et la Trust Policy doit contenir :

```json
"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
```

---

## 3. `sub`

Vérifie que le format correspond.

### Ancien

```text
repo:OWNER/REPO:...
```

### Nouveau

```text
repo:OWNER@OWNER_ID/REPO@REPO_ID:...
```

Dans notre exemple :

```text
repo:cisse17@119404406/django-ecs-devops@1374481008:*
```

Une différence dans le `sub` suffit pour que la Trust Policy ne corresponde pas.

---

## 4. Branche

Par exemple :

```text
repo:OWNER/REPO:ref:refs/heads/main
```

est différent de :

```text
repo:OWNER/REPO:ref:refs/heads/develop
```

---

## 5. Environment

Un workflow utilisant un environment peut avoir :

```text
environment:production
```

dans son `sub`.

La Trust Policy doit donc autoriser le bon contexte.

---

## 6. Provider OIDC

Vérifie que le provider existe :

```bash
aws iam list-open-id-connect-providers
```

et qu'il correspond à :

```text
https://token.actions.githubusercontent.com
```

---

# Checklist

Avant de chercher plus loin :

* [ ] Le provider OIDC GitHub existe dans AWS IAM.
* [ ] L'URL du provider est `https://token.actions.githubusercontent.com`.
* [ ] L'audience est `sts.amazonaws.com`.
* [ ] Le workflow possède `id-token: write`.
* [ ] Le rôle IAM possède une Trust Policy.
* [ ] La Trust Policy vérifie `token.actions.githubusercontent.com:sub`.
* [ ] Le `sub` correspond exactement au format utilisé par le repository.
* [ ] Le repository utilise l'ancien ou le nouveau format attendu.
* [ ] `OWNER_ID` est correct.
* [ ] `REPO_ID` est correct.
* [ ] La branche ou l'environnement correspond au `sub`.
* [ ] Le rôle IAM possède les permissions AWS nécessaires.
* [ ] `terraform apply` a bien été exécuté après modification.
* [ ] `aws sts get-caller-identity` fonctionne depuis GitHub Actions.

---

# Pourquoi utiliser OIDC plutôt que des clés AWS ?

Avec une configuration traditionnelle, on pourrait stocker :

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

dans les secrets GitHub.

Avec OIDC, GitHub Actions demande à AWS des **credentials temporaires** en utilisant son token OIDC.

Cela permet notamment d'éviter de conserver des clés AWS longue durée dans les secrets du repository.

Le principe devient donc :

```text
Pas de clés AWS statiques
          ↓
       OIDC JWT
          ↓
     AWS STS
          ↓
Credentials temporaires
```

---

# À retenir

Le point essentiel avec **GitHub Actions + AWS + OIDC** est la correspondance entre :

```text
sub du token GitHub
```

et :

```text
sub autorisé dans la Trust Policy IAM
```

### Ancien format

```text
repo:OWNER/REPO:...
```

### Nouveau format

```text
repo:OWNER@OWNER_ID/REPO@REPO_ID:...
```

Dans notre exemple :

```text
repo:cisse17@119404406/django-ecs-devops@1374481008:*
```

AWS autorise ensuite GitHub Actions à assumer le rôle via :

```text
sts:AssumeRoleWithWebIdentity
```

et fournit des credentials temporaires.

> **OIDC = pas de clés AWS statiques dans GitHub + credentials temporaires + Trust Policy permettant de contrôler quels workflows peuvent assumer le rôle.**

---

# 📚 Références

* [GitHub Docs — OpenID Connect reference](https://docs.github.com/en/actions/reference/security/oidc)

* [GitHub Docs — Configuring OpenID Connect in Amazon Web Services](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws)

* [GitHub Changelog — Immutable subject claims for GitHub Actions OIDC](https://github.blog/changelog/2026-07-15-immutable-subject-claims-for-github-actions-oidc/)

* [AWS Docs — Creating OpenID Connect identity providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)

* [AWS Docs — Creating a role for OpenID Connect federation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)

* [aws-actions/configure-aws-credentials](https://github.com/aws-actions/configure-aws-credentials)
