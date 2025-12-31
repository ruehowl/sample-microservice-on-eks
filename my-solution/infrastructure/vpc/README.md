# VPC Infrastructure Module

This module contains the foundational networking infrastructure for the EKS cluster and related services.

## Components

- **VPC**: Virtual Private Cloud with DNS support
- **Subnets**: Public and private subnets across multiple Availability Zones (AZ1, AZ2)
- **Internet Gateway**: Public internet access for public subnets
- **NAT Gateways**: Managed NAT gateways for outbound traffic from private subnets
- **Route Tables**: Routing configuration for public and private subnets
- **Network ACLs**: Default network access control

## Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets (Internet access via IGW)
│   ├── AZ1: 10.0.1.0/24
│   └── AZ2: 10.0.2.0/24
├── Private Subnets (Outbound via NAT)
│   ├── AZ1: 10.0.10.0/24
│   └── AZ2: 10.0.11.0/24
├── Internet Gateway
└── NAT Gateways (one per AZ for HA)
```

## State Management

This module maintains its own isolated Terraform state:
- **State Bucket**: `rahul-varghese-sleek-task-terraform-state-bucket`
- **State Key**: `sre-assessment/vpc/terraform.tfstate`
- **Region**: `us-east-1`

## Files

- `provider.tf`: AWS provider and state configuration
- `variables.tf`: Input variables for VPC configuration
- `vpc.tf`: VPC, subnets, gateways, and routing resources
- `outputs.tf`: Output values for cross-stack references

## Usage

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Outputs

Outputs from this module are used by other infrastructure modules (EKS, document-service, etc.):
- `vpc_id`: VPC identifier
- `vpc_cidr`: VPC CIDR block
- `public_subnet_id`: Public subnet ID
- `private_subnet_id`: Private subnet ID
- `internet_gateway_id`: IGW identifier
- `nat_gateway_id`: NAT Gateway identifier
