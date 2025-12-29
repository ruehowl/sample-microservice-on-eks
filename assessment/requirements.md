# Assessment Requirements

## Overview

Build a production-ready document service with complete infrastructure, Kubernetes deployment, CI/CD, observability, and security. The service must handle high read traffic with caching, ensure data durability, and be deployable to AWS using Infrastructure as Code.

## 1. Application Requirements

### 1.1 Core Functionality

Build a REST API service that implements document storage and retrieval:

- PUT /documents/{id} – Store a document
  - Request Body: `{"content": "string"}`
  - Response: `200 OK` with document metadata
  - Content max size: 100 KB
  - Must persist to durable storage
  
- GET /documents/{id} – Retrieve a document
  - Response: `200 OK` with `{"id": "string", "content": "string"}`
  - Response: `404 Not Found` if document doesn't exist
  - Must use cache for performance (read traffic is 10× write traffic)
  - Latency target: < 50 ms (p95) for reads

- Health Check: GET /health
  - Returns `200 OK` with service status
  - Should check both storage and cache connectivity

### 1.2 Non-Functional Requirements

Performance:
- Read traffic is 10× higher than write traffic
- Read latency target: < 50 ms (p95)
- System must tolerate cache restarts without data loss
- System must tolerate node restarts without data loss

Durability:
- Data loss is not acceptable
- Documents must be stored in durable storage (S3, RDS, DynamoDB, etc.)
- Cache is for performance only, not primary storage

Reliability:
- Service must handle cache failures gracefully
- Service must handle storage failures with appropriate error responses
- No single point of failure

### 1.3 Cache Requirements

Must-Have:
- Implement caching strategy (read-through, write-through, or cache-aside)
- Handle cache misses correctly
- Handle cache invalidation on document updates
- Graceful degradation when cache is unavailable

Nice-to-Have:
- Cache stampede protection
- TTL configuration
- Cache warming strategies
- Metrics for cache hit/miss rates

### 1.4 Technology Choice

- Language: Python (FastAPI, Flask) OR Node.js (Express, NestJS)
- Storage: Choose appropriate durable storage:
  - S3 (object storage)
  - DynamoDB (NoSQL)
  - RDS PostgreSQL/MySQL (relational)
  - Document your choice
- Cache: AWS ElastiCache (Redis or Memcached)

### 1.5 Application Features

Must-Have:
- Input validation (content size limits, ID format)
- Error handling with appropriate HTTP status codes
- Structured JSON logging
- Health check endpoint
- Graceful shutdown handling
- Cache error handling (fallback to storage)

Nice-to-Have:
- Rate limiting
- Request ID tracking
- Metrics endpoint for Prometheus (if using)
- Optimistic locking for concurrent updates

### 1.6 Containerization

- Dockerfile with best practices:
  - Multi-stage build
  - Non-root user
  - Health check instruction
  - Proper layer caching
  - Minimal base image (alpine or distroless)
  
- docker-compose.yml for local development/testing (include cache service)

## 2. Infrastructure Requirements

### 2.1 Core Infrastructure (Terraform)

Must-Have Components:

1. **VPC & Networking**:
   - VPC with CIDR block
   - Public subnets (for ALB, NAT Gateway)
   - Private subnets (for application containers, cache, storage)
   - Internet Gateway
   - NAT Gateway (for private subnet egress)
   - Route tables

2. Container Orchestration (Choose ONE):
   - Option A: EKS
     - EKS cluster (managed)
     - Node group(s) in private subnets
     - IAM roles for service accounts
   - Option B: ECS Fargate
     - ECS cluster
     - Fargate task definition
     - Service definition
     - IAM roles for tasks

3. **Load Balancing**:
   - Application Load Balancer (ALB)
   - Target group(s)
   - Listener rules
   - Health check configuration

4. Storage (Choose ONE):
   - S3: Bucket for document storage
   - DynamoDB: Table for document storage
   - RDS: Database instance (PostgreSQL/MySQL)
   - Document your choice and rationale

5. **Caching**:
   - ElastiCache cluster (Redis or Memcached)
   - Subnet group in private subnets
   - Security group allowing access from application

6. **Container Registry**:
   - ECR repository for application image

7. **State Management**:
   - S3 bucket for Terraform state
   - DynamoDB table for state locking (optional but recommended)

Nice-to-Have:
- Multiple availability zones
- Auto Scaling configuration
- Backup configuration for storage

### 2.2 Kubernetes Deployment

If using EKS, you must provide:

Option A: Kubernetes Manifests (YAML):
- Deployment manifest with:
  - Container image reference
  - Resource limits and requests
  - Environment variables
  - Health checks (liveness, readiness probes)
  - Non-root user configuration
- Service manifest (ClusterIP or NodePort)
- ConfigMap for configuration (if needed)
- Secrets (reference AWS Secrets Manager or use Kubernetes secrets)
- Optional: Ingress manifest

Option B: Helm Charts:
- Complete Helm chart with:
  - values.yaml for configuration
  - templates for Deployment, Service, ConfigMap
  - Chart.yaml with metadata
  - README.md with usage instructions
- Proper templating and parameterization

Requirements:
- Proper resource limits
- Health checks configured
- Environment variables for storage and cache endpoints
- Security best practices (non-root, read-only filesystem where possible)

### 2.3 Security Requirements

Must-Have:

1. **IAM**:
   - Least privilege IAM roles for:
     - EKS node groups / ECS tasks
     - Application service account
     - CI/CD pipeline
   - No hardcoded credentials

2. **Secrets Management**:
   - AWS Secrets Manager for sensitive configuration
   - Application retrieves secrets at runtime
   - Kubernetes secrets or service account integration

3. **Network Security**:
   - Security groups with minimal required ports
   - Private subnets for application workloads, cache, and storage
   - ALB in public subnets only
   - No direct internet access for application containers

4. **Container Security**:
   - Non-root user in container
   - Security group rules restrict traffic appropriately
   - Minimal base images

Nice-to-Have:
- AWS WAF on ALB
- Container image scanning in CI/CD
- Network ACLs
- VPC Flow Logs
- Pod Security Policies (EKS)

### 2.4 Terraform Best Practices

- Modular structure (use modules for reusable components)
- Variables for all configurable values
- Outputs for important resources (ALB DNS, cluster endpoint, cache endpoint, etc.)
- Proper resource tagging
- State file in S3 with versioning
- Comments explaining non-obvious decisions

## 3. CI/CD Pipeline Requirements

### 3.1 Pipeline Stages

Must-Have:

1. **Build & Test**:
   - Install dependencies
   - Run unit tests (if applicable)
   - Build Docker image
   - Tag image appropriately

2. **Security Scanning**:
   - Scan container image for vulnerabilities (Trivy, Snyk, or similar)
   - Fail pipeline on high/critical vulnerabilities

3. **Infrastructure**:
   - Terraform validate
   - Terraform plan
   - Terraform apply (on main/master branch or manual approval)

4. **Deploy**:
   - Push image to ECR
   - Update Kubernetes deployment / ECS service
   - Verify deployment health

Nice-to-Have:
- Integration tests
- Terraform plan as PR comment
- Blue-green or canary deployment
- Rollback mechanism
- Notifications (Slack, email)

### 3.2 Pipeline Technology

- **GitHub Actions** (preferred) OR **Bitbucket Pipelines**
- Pipeline should be in `.github/workflows/` or `bitbucket-pipelines.yml`
- Use secrets for AWS credentials
- Support for feature branch deployments (optional)

## 4. Observability Requirements

### 4.1 Logging

Must-Have:
- Structured JSON logging from application
- CloudWatch Log Groups for application logs
- Log retention policy (7-30 days)
- Log aggregation at service level
- Log cache operations (hits, misses, errors)

Nice-to-Have:
- Log correlation IDs
- Centralized log aggregation
- Log parsing and alerting on errors

### 4.2 Monitoring

Must-Have:
- CloudWatch custom metrics:
  - Request count (by endpoint, by status code)
  - Request latency (p50, p95, p99) - critical for read latency target
  - Error rate (4xx, 5xx)
  - Cache hit/miss rates
  - Storage operation metrics
- CloudWatch dashboard with key metrics
- At least one CloudWatch alarm (e.g., high error rate, high latency)

Nice-to-Have:
- Additional metrics (CPU, memory, etc.)
- Multiple dashboards
- SLO/SLI definitions
- Prometheus + Grafana (if using EKS)
- Cache performance metrics

### 4.3 Tracing (Optional Bonus)

- OpenTelemetry integration
- Distributed tracing setup
- Trace visualization

## 5. Documentation Requirements

### 5.1 Must-Have Documentation

1. Architecture Document (`docs/architecture.md`):
   - Architecture diagram (ASCII art, Mermaid, or image)
   - Component descriptions (storage, cache, application)
   - Data flow (write path, read path)
   - Key design decisions:
     - Why you chose your storage solution
     - Why you chose your caching strategy
     - How you handle cache failures
     - How you ensure durability

2. Deployment Runbook (`docs/deployment.md`):
   - Prerequisites
   - Step-by-step deployment instructions
   - How to access the service
   - How to verify deployment
   - How to test the service

3. Troubleshooting Guide (`docs/troubleshooting.md`):
   - Common issues and solutions
   - How to check logs
   - How to verify infrastructure
   - How to test cache functionality
   - Rollback procedures

### 5.2 Nice-to-Have Documentation

- Cost estimates
- Scaling guide
- Security considerations
- Performance tuning tips
- Cache strategy explanation

## 6. Testing Requirements

### 6.1 Application Testing

- At minimum: Manual testing of endpoints
- Preferred: Unit tests for core logic
- Bonus: Integration tests
- **Critical**: Test cache behavior (hits, misses, failures)

### 6.2 Infrastructure Testing

- Terraform validate and plan should succeed
- Manual verification of deployed infrastructure
- Bonus: Automated infrastructure tests (Terratest, etc.)

### 6.3 Performance Testing (Optional)

- Load testing to verify latency targets
- Cache performance validation

## 7. Design Considerations

### 7.1 Storage vs Cache

Critical: You must clearly demonstrate understanding of:
- When to use storage vs cache
- How to handle cache failures
- How to ensure data durability
- Cache invalidation strategies

### 7.2 Failure Scenarios

Your design should handle:
- Cache unavailable (fallback to storage)
- Storage unavailable (appropriate error handling)
- Concurrent updates (consider optimistic locking)
- Cache stampede (if implementing)

### 7.3 Scalability

Consider:
- How to scale from 1K to 1M documents
- Cache sizing and scaling
- Storage scaling
- Read vs write scaling patterns

## 8. Cost Considerations

- Document estimated monthly costs
- Use cost-effective instance types
- Consider spot instances for EKS node groups (optional)
- Clean up resources after assessment (if requested)

## 9. Deliverables Checklist

Your submission should include:

- [ ] Application code with Dockerfile
- [ ] Complete Terraform infrastructure code
- [ ] Kubernetes manifests OR Helm charts
- [ ] CI/CD pipeline configuration (GitHub Actions or Bitbucket Pipelines)
- [ ] Documentation (architecture, deployment, troubleshooting)
- [ ] Working deployment in AWS
- [ ] Summary of design decisions (especially storage and cache choices)
- [ ] Cost estimate

## 10. Scope Boundaries

What's NOT Required (to keep within 2-3 hours):

- Multi-region deployment
- Complex authentication/authorization
- Full test coverage
- Production-grade disaster recovery
- Advanced networking (VPN, Direct Connect)
- Multi-tenant architecture
- Document versioning
- Search functionality

Focus on demonstrating SRE-specific skills:
- Reliability Engineering: Error handling, failure modes, graceful degradation
- Cache Correctness: Proper cache strategy (read-through/write-through/cache-aside), invalidation, cold starts
- Data Durability: Storage choice rationale, consistency guarantees, data loss prevention
- Operational Thinking: Observability (what metrics matter?), failure scenarios, troubleshooting readiness
- Infrastructure Design: Scalability patterns, resource selection, cost optimization
- Security Best Practices: IAM, secrets management, least privilege
- Clean, Maintainable Code: Well-organized Terraform, readable application code

## 11. Getting Help

If you encounter issues with:
- AWS account access: Contact your assessment coordinator
- Technical questions: Reach out to your point of contact
- Clarifications on requirements: Don't hesitate to ask

