# Architecture

This document is split into:
- **Application architecture** (runtime behavior)
- **Operations architecture** (how it is built, tested, deployed, and operated)

## Application Architecture (Runtime)

### Overview
- **Durable storage**: Amazon S3 (system of record)
- **Caching**: Redis (intended for Amazon ElastiCache for Redis)
- **Compute**: Amazon EKS (Kubernetes) deployed via Helm

### Runtime Data Flow
- **PUT `/documents/{id}`**
	- Writes content to **S3**.
	- Deletes the corresponding Redis key (cache invalidation) to avoid stale reads.
- **GET `/documents/{id}`**
	- Tries **Redis** first (cache-aside).
	- On miss or cache error, fetches from **S3**, then populates Redis with a TTL.

### Key Design Decisions

#### Storage: S3 (Durability-first)
- Stores objects under a configurable prefix (`S3_KEY_PREFIX`).
- Supports S3 server-side encryption via `S3_SSE` (default `AES256`; supports `aws:kms` when `S3_KMS_KEY_ID` is set).

#### Caching: Redis (Cache-aside)
- Cache-aside pattern for correctness and simplicity.
- Cache is treated as optional: Redis failures degrade to S3 reads.
- TTL is configurable (`CACHE_TTL_SECONDS`).

#### Health & readiness
- `/health/live`: process-level liveness
- `/health/ready`: dependency readiness (S3 required; Redis optional)

## Operations Architecture

### High-level topology
- **GitHub Actions** builds/tests the app and runs smoke tests.
- **Terraform (modular)** provisions AWS foundations and service dependencies.
- **ECR** stores container images.
- **Helm** deploys to **EKS**.
- **ALB Ingress** (via AWS Load Balancer Controller) exposes the service.
- **CloudWatch** collects logs/metrics/alarms.

### Infrastructure deployment choices

#### IaC: modular Terraform states
Terraform is intentionally split into separate modules/states to keep blast radius small and allow ordered applies/destroys:
- `my-solution/infrastructure/github-cicd`: GitHub OIDC/IAM bootstrap for CI
- `my-solution/infrastructure/vpc`: networking primitives (public/private subnets, IGW, NAT)
- `my-solution/infrastructure/eks`: Kubernetes control plane + node groups
- `my-solution/infrastructure/document-service`: service dependencies (S3, ElastiCache, ECR, IAM, security groups, monitoring)

#### AWS services
- **S3**: `my-solution/infrastructure/document-service/storage.tf`
- **ElastiCache (Redis)**: `my-solution/infrastructure/document-service/cache.tf`
- **ECR**: `my-solution/infrastructure/document-service/ecr.tf` (scan-on-push, lifecycle policy)
- **CloudWatch**: `my-solution/infrastructure/document-service/monitoring.tf` (log groups, dashboard, alarms)

#### Security model (ops-facing)
- Kubernetes service accounts are set up to use **IRSA** via annotations (see `my-solution/kubernetes/helm/values/document-service-dev.yaml`).
- The AWS Load Balancer Controller also uses an IAM role via service-account annotation (see `my-solution/kubernetes/helm/values/aws-load-balancer-controller.yaml`).
- Network restrictions are enforced with security groups in `my-solution/infrastructure/document-service/security_groups.tf`.

### CI/CD pipeline

CI/CD is intentionally scoped to work from a single repository and this limitaion is influenced the choices made.

#### Workflows
- **Terraform**: `.github/workflows/terraform.yml`
	- Supports `plan/apply/destroy` per module via `workflow_dispatch` inputs.
	- Intended apply order: `github-cicd` → `vpc` → `eks` → `document-service`.
- **Build + Deploy**: `.github/workflows/deploy.yml`
	- `build-and-test`: install deps → `pytest` → build image → smoke test via `docker compose` → `helm lint` + `helm template`.
	- `deploy` (main/manual): build+push to ECR → configure kubeconfig → install/upgrade ALB controller → `helm upgrade --install` app.

#### Test coverage and smoke tests
- **Unit tests** live in `my-solution/app/tests/` and run in CI via `pytest`.
- **Smoke tests** run in CI by:
	- bringing up the stack with `docker compose` (LocalStack + Redis + app)
	- calling `/health/live` and `/health/ready`
	- executing a PUT/GET roundtrip for a document
- **Chart checks** run in CI via `helm lint` and rendering manifests with `helm template`.

### Helm/Kubernetes deployment

#### Chart layout
- Chart: `my-solution/kubernetes/helm/document-service`
- Templates: `my-solution/kubernetes/helm/document-service/templates/` (Deployment/Service/Ingress/HPA/ServiceAccount)
- Defaults: `my-solution/kubernetes/helm/document-service/values.yaml`
- Environment overrides: `my-solution/kubernetes/helm/values/document-service-dev.yaml`

#### Release behavior
- The deploy workflow upgrades/installs the Helm release `document-service`.
- Image is injected at deploy time via `--set image.repository=... --set image.tag=...`.
- Liveness/readiness probes are configured to match `/health/live` and `/health/ready`.

### Repository structure (ops-relevant)
Key paths used for operations and delivery:
- `my-solution/app/`: FastAPI service, Dockerfile, Compose, unit tests
- `my-solution/infrastructure/`: Terraform modules (VPC/EKS/service deps/CI bootstrap)
- `my-solution/kubernetes/`: Helm chart and environment values
- `.github/workflows/`: CI/CD workflows (Terraform + Build/Deploy)

### Cost notes (high-level)
Primary drivers:
- EKS (control plane + worker nodes)
- NAT Gateways (VPC module provisions one per AZ)
- ALB (internet-facing ingress)
- ElastiCache
- CloudWatch ingestion/retention
Notes:
- Spot instances are supported for EKS nodes to reduce compute costs.
- CD is easy to deploy and destoy via GitHub Actions, allowing cost-free idle time.
- 2 AZs are used as it is the recommended minimum for EKS clusters for cluster creation

## Implementation Notes / TODOs



### Enable ElastiCache in the live (AWS) environment
- Wire the runtime configuration to point to the provisioned ElastiCache endpoint (and prefer TLS-in-transit):
	- set `CACHE_HOST`, `CACHE_PORT`, and `CACHE_SSL=true` for the Helm deployment.

### Redis authentication via IAM (code + infra)
- If using **ElastiCache Redis IAM authentication**, the app must generate short-lived auth tokens and refresh them.
	- Code change: create a Redis auth token provider (SigV4) and set `CACHE_USERNAME` + `CACHE_PASSWORD` (token) when connecting.
	- Infra change: enable IAM auth on the Redis cluster/replication group and grant the pod IAM role permissions for token generation.
- Alternative (simpler): use Redis AUTH with user/password (user groups) and store the secret in a managed secret store (Secrets Manager) injected into the pod.

### Use CI OIDC roles for Terraform + Helm deploy
- The repo has a `github-cicd` Terraform module intended to bootstrap CI IAM/OIDC, but the workflows currently use long-lived secrets (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`).
- Recommended change:
	- Use GitHub OIDC in **both** `.github/workflows/terraform.yml` and `.github/workflows/deploy.yml` via `aws-actions/configure-aws-credentials` with `role-to-assume`.
	- Remove static AWS keys from GitHub Secrets once OIDC is working.

### Security guideline adaptations

#### Health endpoints exposure
- Kubernetes needs liveness/readiness endpoints for probes; instead of removing them entirely:
	- Keep `/health/live` and `/health/ready` for in-cluster use.
	- Prevent public access by default (recommended):
		- do not route `/health/*` through the public Ingress, or
		- add ALB Ingress rules/conditions to restrict source ranges, or
		- move health endpoints to a separate internal-only Ingress.

#### Pipeline security measures (not yet implemented)
- Enable image and dependency scanning:
	- uncomment/add Trivy scan in `.github/workflows/deploy.yml`.
	- add Python dependency scanning (e.g., `pip-audit`) and basic SAST (e.g., `bandit`).

### Proper app versioning and releases (CI/CD)
- Introduce a release/versioning strategy (e.g., SemVer) and make image tags immutable