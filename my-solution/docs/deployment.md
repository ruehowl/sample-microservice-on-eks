# Deployment (Operations Runbook)

This runbook focuses on the operations workflow (infra provisioning + application delivery).


Deployment order (recommended):
1) **CI bootstrap (GitHub OIDC/IAM)** → 2) **VPC** → 3) **EKS** → 4) **Service dependencies** → 5) **Application deploy (Helm)**

## Prerequisites

### Required GitHub Secrets
Both `.github/workflows/terraform.yml` and `.github/workflows/deploy.yml` expect AWS credentials in GitHub Secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`

> Note: `github-cicd` is the module intended to create CI IAM/OIDC resources. You still need *some* initial AWS credentials to run Terraform the first time.

## Terraform applies (in order)

All Terraform automation is in `.github/workflows/terraform.yml`.

### How to trigger

#### Option A: GitHub UI
1. Go to **Actions** → **Terraform**
2. Click **Run workflow**
3. Select the `action` input


## Step 1 — CI bootstrap (github-cicd)
Runs Terraform in `my-solution/infrastructure/github-cicd`.

Trigger:
- `action = github-cicd-apply`

## Step 2 — VPC
Runs Terraform in `my-solution/infrastructure/vpc`.

Trigger:
- `action = vpc-apply`

## Step 3 — EKS
Runs Terraform in `my-solution/infrastructure/eks`.

Trigger:
- `action = eks-apply`

## Step 4 — Document service infrastructure
Runs Terraform in `my-solution/infrastructure/document-service`.

This module provisions the service dependencies (e.g., storage, cache, IAM, monitoring) used by the app.

Trigger:
- `action = document-service-apply`

## Step 5 — Deploy the application (Helm)

Application build/test/deploy is in `.github/workflows/deploy.yml`.

### Trigger
- Push a commit to `main` that changes `my-solution/app/**` or `my-solution/kubernetes/**`, **or**
- Manually run **Actions** → **Build and Deploy** → **Run workflow**.

### What it does
- Builds and tests the app (unit tests)
- Builds a Docker image and pushes it to ECR
- Updates kubeconfig for the EKS cluster
- Installs/upgrades AWS Load Balancer Controller using `my-solution/kubernetes/helm/values/aws-load-balancer-controller.yaml`
- Deploys the service via Helm:
	- Chart: `my-solution/kubernetes/helm/document-service`
	- Values: `my-solution/kubernetes/helm/values/document-service-dev.yaml`
	- Image: set at deploy time via `--set image.repository=... --set image.tag=...`

## Recommended destroy order
When cleaning up, destroy in reverse order to reduce dependency failures:
1) `document-service-destroy` → 2) `eks-destroy` → 3) `vpc-destroy` (and `github-cicd-destroy` last, if used)

