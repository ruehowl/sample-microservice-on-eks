# Principal SRE Assessment

## Overview

This assessment evaluates your ability to design and deploy production infrastructure for a document service. You'll build a complete system using AWS, container orchestration, and Infrastructure as Code.

Time commitment: 2-3 hours  
Tech stack: AWS, EKS/ECS, Terraform, Docker, Kubernetes, CI/CD

## The Challenge

Build and deploy a document service that:

- Stores and retrieves documents with durability guarantees
- Uses caching to optimize read performance (10× read-to-write ratio)
- Runs on containerized infrastructure (EKS or ECS)
- Uses Infrastructure as Code (Terraform)
- Includes Kubernetes manifests or Helm charts for deployment
- Includes a complete CI/CD pipeline
- Implements observability (logging, monitoring, alerting)
- Follows security best practices
- Includes comprehensive documentation

## Prerequisites

Before starting, ensure you have:

1. **AWS Account**: You'll use your own AWS account for this assessment. Make sure you have:
   - An active AWS account with appropriate permissions
   - Ability to create resources (VPC, EKS/ECS, S3, DynamoDB, ElastiCache, etc.)
   - AWS CLI v2 configured with your credentials
   - Budget alerts configured (recommended) to monitor costs

2. **Local Tools Installed**:
   - AWS CLI v2
   - Terraform >= 1.5.0
   - Docker Desktop
   - kubectl (if using EKS)
   - Helm (if using Helm charts)
   - Git
   - A code editor of your choice

3. **Knowledge Areas**:
   - AWS services (VPC, EKS/ECS, IAM, CloudWatch, S3, ElastiCache, etc.)
   - Terraform
   - Containerization (Docker)
   - Kubernetes (if choosing EKS)
   - CI/CD pipelines (GitHub Actions or Bitbucket Pipelines)

## Getting Started

1. Accept the GitHub repository invitation for your dedicated repository: `principal-sre-assessment-<YourName>`
2. Review the requirements in [assessment/requirements.md](assessment/requirements.md)
3. Configure AWS credentials using your own AWS account
4. Optionally use the [starter template](assessment/starter-template/) as a starting point
5. Begin implementation

## Project Structure

Your solution should be organized as follows:

```
your-solution/
├── app/                    # Application code
│   ├── Dockerfile
│   ├── docker-compose.yml  # For local testing
│   └── [your code]
├── infrastructure/         # Terraform code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/           # Optional: modular structure
├── kubernetes/             # Kubernetes manifests or Helm charts
│   ├── deployment.yaml    # (if using plain YAML)
│   ├── service.yaml
│   └── [other manifests]
│   OR
│   └── helm/              # (if using Helm)
│       └── document-service/
├── ci-cd/                  # CI/CD pipeline files
│   └── .github/workflows/  # GitHub Actions
│   OR
│   └── bitbucket-pipelines.yml  # Bitbucket Pipelines
└── docs/                   # Documentation
    ├── architecture.md     # Architecture diagram and explanation
    ├── deployment.md       # Deployment runbook
    └── troubleshooting.md  # Troubleshooting guide
```

## Lite CI Example

This repository now includes a `liteci` intent that discovers `component.yaml` manifests from the Terraform modules and Helm deployment under `my-solution/`.

Pinned version: `liteci v0.3.0`

Local workflow:

```bash
go install github.com/sourceplane/liteci/cmd/liteci@v0.3.0
liteci validate --intent intent.yaml
liteci component --intent intent.yaml --long
liteci plan --intent intent.yaml --config-dir lite-ci/compositions --output .liteci/plan.json --view dag
```

The PR workflow at `.github/workflows/liteci.yml` also uses `v0.3.0` and generates a changed-only plan when a pull request touches the infrastructure, Helm, intent, or component manifests.

## Requirements

See [assessment/requirements.md](assessment/requirements.md) for detailed requirements covering:

- Application functionality (document storage and retrieval)
- Infrastructure components
- Kubernetes/Helm deployment
- CI/CD pipeline
- Observability
- Security
- Documentation

## Evaluation Criteria

Submissions are evaluated on:

- SRE Fundamentals (30%): Reliability patterns, error handling, failure modes, cache correctness, data durability
- Infrastructure Design (25%): Architecture decisions, scalability patterns, resource selection (storage, cache)
- Operational Excellence (20%): Observability (metrics, logs, alerts), monitoring, troubleshooting readiness
- Security & Best Practices (15%): IAM, secrets management, network security, container hardening
- Code Quality & Automation (10%): Terraform modules, CI/CD pipeline, code organization

## Submission

1. Push your code to your repository: `principal-sre-assessment-<YourName>`
2. Ensure the repository is accessible to reviewers
3. Include a summary document (README or separate doc) with:
   - Architecture overview
   - Key design decisions (especially around storage and caching)
   - Any assumptions or trade-offs made
   - Instructions for deploying your solution
   - Estimated AWS costs

See [docs/submission-guidelines.md](docs/submission-guidelines.md) for complete submission instructions.

## Resource Management

**Important**: Only run AWS resources when necessary to minimize costs.

**Resource Lifecycle**:
1. **During Development**: Run resources as needed for development and testing
2. **After Development**: Destroy all resources immediately after completing development
3. **Before Follow-up Discussion**: Redeploy your infrastructure before the scheduled discussion
4. **During Discussion**: Keep resources running for verification and modifications
5. **After Discussion**: Destroy all resources once the discussion is complete

**How to Deploy/Destroy**:
- Deploy: Use `terraform apply` in your infrastructure directory
- Destroy: Use `terraform destroy` in your infrastructure directory, or follow the [Resource Cleanup Guide](docs/RESOURCE-CLEANUP.md)

**Why**: Resources continue to incur costs while running. Destroying resources when not in use minimizes costs and demonstrates operational maturity.

See [docs/RESOURCE-CLEANUP.md](docs/RESOURCE-CLEANUP.md) for detailed cleanup instructions.

## Time Management Tips

Given the 2-3 hour timeframe, prioritize:

1. Must-Have (Core SRE functionality):
   - Working document service (PUT/GET endpoints)
   - Durable storage (S3, DynamoDB, or RDS) with proper choice rationale
   - Cache implementation (ElastiCache Redis/Memcached) with correct strategy
   - Cache failure handling (graceful degradation)
   - Terraform infrastructure (VPC, EKS/ECS, ALB)
   - Kubernetes manifests or Helm charts
   - Basic CI/CD pipeline
   - Security basics (IAM, secrets)
   - Essential observability (logs, key metrics)

2. Nice-to-Have (If time permits):
   - Advanced monitoring dashboards
   - Auto-scaling configuration
   - Cache stampede protection
   - Comprehensive runbooks
   - Advanced security hardening

## Cost Optimization Guide

Since you're using your own AWS account, here are strategies to keep costs minimal while completing the assessment:

### Target Cost: $5-10 for Complete Assessment

**Recommended Approach** (Balanced - ~$5-8):
- Use **ECS Fargate** instead of EKS (saves ~$0.10/hour on control plane)
- Use **t3.small** or minimal Fargate instances (0.25 vCPU, 0.5 GB RAM)
- Use **single Availability Zone** for NAT Gateway (saves 50% on NAT costs)
- Use **Spot Instances** if choosing EKS (70% discount on compute)
- Clean up resources immediately after testing

**Minimal Cost Approach** (~$2-3):
- ECS Fargate with minimal resources (0.25 vCPU, 0.5 GB RAM)
- Single AZ deployment
- Minimal CloudWatch logging
- Clean up within 24 hours

### Cost-Saving Strategies

1. **Choose ECS Fargate over EKS**
   - EKS control plane: $0.10/hour = $2.40/day
   - ECS Fargate: No control plane cost
   - **Savings**: ~$2-3 per day

2. **Use Small Instance Types**
   - t3.small: $0.0208/hour vs t3.medium: $0.0416/hour
   - Minimal Fargate: 0.25 vCPU, 0.5 GB RAM
   - **Savings**: 50% on compute costs

3. **Single Availability Zone**
   - NAT Gateway: $0.045/hour per AZ
   - Single AZ acceptable for assessment
   - **Savings**: 50% on NAT Gateway costs

4. **Use Spot Instances (EKS only)**
   - Spot instances: ~70% discount
   - t3.medium spot: ~$0.0125/hour vs $0.0416/hour on-demand
   - **Savings**: ~70% on compute

5. **Minimize Data Transfer**
   - Test locally first, then deploy
   - Use same region for all resources
   - **Savings**: Minimal data transfer costs

6. **Set Up Budget Alerts**
   ```bash
   # Create budget alert at $5 threshold
   aws budgets create-budget \
     --account-id $(aws sts get-caller-identity --query Account --output text) \
     --budget file://budget.json \
     --notifications-with-subscribers file://notifications.json
   ```
   - Alert at 50% ($2.50), 80% ($4.00), 100% ($5.00)
   - Prevents unexpected costs

7. **Tag All Resources**
   - Tag with: `Project: assessment`, `Environment: test`
   - Enables cost tracking and easy cleanup
   - Use AWS Cost Explorer to monitor

8. **Clean Up Promptly**
   - Delete resources immediately after testing
   - Use `terraform destroy` to remove all resources
   - **Critical**: Resources continue to incur costs while running

### Cost Breakdown (ECS Fargate - Recommended)

| Component | Hourly Cost | 3 Hours | Daily (if left running) |
|-----------|-------------|----------|-------------------------|
| ECS Fargate (0.25 vCPU, 0.5 GB) | $0.014 | $0.04 | $0.34 |
| Application Load Balancer | $0.0225 | $0.07 | $0.54 |
| NAT Gateway (single AZ) | $0.045 | $0.14 | $1.08 |
| CloudWatch Logs | $0.001 | $0.003 | $0.02 |
| ECR Storage | $0.001 | $0.003 | $0.02 |
| **Total** | **~$0.08** | **~$0.25** | **~$2.00** |

**Assessment Cost**: ~$0.25 for 3 hours of active work  
**With Review Period** (7 days): ~$14 if left running  
**Recommended**: Clean up immediately after completion = **$0.25-0.50 total**

### Cost Monitoring

1. **Set Up AWS Budgets**:
   - Go to AWS Billing → Budgets
   - Create budget: $5 limit
   - Set alerts at 50%, 80%, 100%

2. **Use Cost Explorer**:
   - Monitor daily spending
   - Filter by tags to track assessment costs
   - Identify cost drivers

3. **Enable Billing Alerts**:
   - CloudWatch billing alarms
   - Email notifications for spending thresholds

### Cleanup Checklist

After completing your assessment, ensure you delete:
- ✅ ECS cluster or EKS cluster
- ✅ EC2 instances (if using EKS)
- ✅ Application Load Balancer
- ✅ NAT Gateway
- ✅ VPC and subnets
- ✅ Security groups
- ✅ CloudWatch log groups
- ✅ ECR container images
- ✅ S3 buckets (if created)
- ✅ DynamoDB tables (if created)
- ✅ ElastiCache clusters
- ✅ IAM roles and policies (if created)

**Quick Cleanup**:
```bash
cd infrastructure
terraform destroy -auto-approve
```

## Assessment Approach

We use real AWS infrastructure for this assessment to evaluate production-ready skills. For details on why we use real cloud infrastructure instead of local setup, see [Assessment Justification](docs/ASSESSMENT-JUSTIFICATION.md).

**Cost Information** (if using your own AWS account):
- **Target cost**: $5-10 for the complete assessment
- **Minimal cost**: $2-3 with careful resource selection
- See [Cost Optimization Guide](#cost-optimization-guide) above for detailed strategies
- See [Cost Estimates](planning/05-COST-ESTIMATES.md) for detailed breakdown
- **Critical**: Set up budget alerts and clean up resources promptly after completion

## Submission & Preparation Requirements

To ensure your assessment can be properly reviewed, please ensure the following:

### Before Submission

1. **Repository Access**
   - Ensure your repository is accessible to reviewers
   - All code should be pushed to the main/master branch
   - Include a clear README with setup instructions

2. **Documentation Requirements**
   - **Architecture Diagram**: Visual representation of your infrastructure
   - **Design Decisions**: Document key choices (storage type, caching strategy, etc.)
   - **Deployment Guide**: Step-by-step instructions to deploy your solution
   - **Cost Analysis**: Estimated costs and optimization strategies used
   - **Troubleshooting Guide**: Common issues and solutions

3. **Code Organization**
   - Well-structured Terraform modules
   - Clear separation of concerns (infrastructure, application, CI/CD)
   - Meaningful variable names and comments
   - Proper error handling and validation

4. **Infrastructure State**
   - **Resource Management**: Run resources during development, destroy after completion, then redeploy before follow-up discussion
   - Infrastructure should be readily deployable and modifiable
   - Terraform state should be available (or include clear instructions to recreate)
   - Your setup should allow for quick deployment and changes

5. **Testing & Validation**
   - Document how to test your solution
   - Include test results or validation steps
   - Ensure endpoints are accessible (if applicable)

### Follow-Up Discussion

After submission, you may be invited for a follow-up discussion about your solution. Please be prepared to:

1. **Deploy Before Discussion**
   - Redeploy your infrastructure before the scheduled discussion
   - Ensure your solution is accessible and ready for demonstration
   - Test that your deployment works correctly before the discussion

2. **Demonstrate Your Solution**
   - Your infrastructure should be deployed and accessible during the discussion
   - Be ready to show your solution in action
   - Walk through your architecture and design decisions

3. **Discuss Your Implementation**
   - Explain your design choices and rationale
   - Discuss trade-offs you made
   - Walk through key components of your code

4. **Make Modifications**
   - Be prepared to make changes or improvements during the discussion
   - Your setup should allow for quick modifications and redeployment
   - You may be asked to implement specific changes or enhancements
   - Feel free to use AI tools or documentation (Google, AWS docs, etc.) as needed

5. **Operational Readiness**
   - Be ready to discuss how your solution handles various scenarios
   - Explain your monitoring and observability setup
   - Discuss scaling and reliability considerations

6. **Clean Up After Discussion**
   - Destroy all resources after the discussion is complete
   - This helps minimize costs and demonstrates operational maturity

### Assessment Criteria

1. **SRE Fundamentals** (30%)
   - Reliability patterns and error handling
   - Cache correctness and data durability
   - Failure mode analysis
   - Graceful degradation

2. **Infrastructure Design** (25%)
   - Architecture decisions and rationale
   - Scalability patterns
   - Resource selection (storage, cache, compute)
   - Network design

3. **Operational Excellence** (20%)
   - Observability (metrics, logs, alerts)
   - Monitoring dashboards
   - Troubleshooting readiness
   - Documentation quality

4. **Security & Best Practices** (15%)
   - IAM roles and policies
   - Secrets management
   - Network security
   - Container hardening

5. **Code Quality & Automation** (10%)
   - Terraform module structure
   - CI/CD pipeline completeness
   - Code organization
   - Automation level

### Submission Checklist

Before submitting, verify:
- [ ] All code is pushed to repository
- [ ] README includes setup and deployment instructions
- [ ] Architecture diagram is included
- [ ] Design decisions are documented
- [ ] Cost analysis is provided
- [ ] Infrastructure is accessible (if keeping resources running)
- [ ] Terraform state is available or recreation instructions provided
- [ ] CI/CD pipeline is functional
- [ ] Monitoring and alerting are configured
- [ ] Security best practices are implemented
- [ ] Documentation is complete and clear

### Post-Submission

- **Resource Management**: See [Resource Management](#resource-management) section above for complete lifecycle
- **Be Prepared**: Your codebase should be well-organized and easy to modify
- **Respond Promptly**: Respond to any communication in a timely manner
- **Cost Management**: Use budget alerts and destroy resources when not in use

Focus on demonstrating your engineering judgment, practical skills, and ability to make thoughtful trade-offs. Quality over quantity: a well-architected, secure, and maintainable solution is more valuable than one with every possible feature.

