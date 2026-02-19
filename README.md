# HealthFlow AWS Landing Zone

Multi-account AWS architecture for a HIPAA-compliant healthcare SaaS platform. Built with Terraform to demonstrate Solutions Architect capabilities.

## Architecture Overview

- **Multi-Account Structure**: Separate Dev, Staging, and Production accounts for security isolation
- **Network Design**: VPC per account with public/private subnet architecture across 2 availability zones
- **High Availability**: Resources distributed across us-east-1a and us-east-1b
- **Security**: Private subnets by default, NAT Gateway for outbound traffic, Internet Gateway for load balancers only

## Infrastructure Components

### Networking (`terraform/networking/`)
- 3 VPCs (Dev: 10.3.0.0/16, Staging: 10.4.0.0/16, Prod: 10.5.0.0/16)
- Public subnets for load balancers and NAT Gateways
- Private subnets for application and database tiers
- Route tables with proper traffic segregation

### Security (`terraform/security/`)
- **CloudTrail**: Organization-wide audit logging with 1-year retention
- **GuardDuty**: AI-powered threat detection with malware scanning
- **Security Hub**: Compliance dashboard (CIS Benchmark, PCI-DSS)
- **AWS Config**: Resource configuration tracking and compliance rules
- All logs encrypted and stored in immutable S3 buckets

### Modules (`terraform/modules/vpc/`)
- Reusable VPC module with configurable CIDR blocks
- Automatic subnet creation across availability zones
- Integrated NAT Gateway and Internet Gateway setup

## Project Structure
```
healthflow-landing-zone/
├── docs/
│   ├── REQUIREMENTS.md          # Business requirements and constraints
│   └── ARCHITECTURE.html        # Visual architecture diagram
├── terraform/
│   ├── modules/
│   │   └── vpc/                 # Reusable VPC module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── networking/              # VPC deployment
│       ├── main.tf
│       ├── variables.tf
│       └── provider.tf
└── README.md
```

## Usage
```bash
# Initialize Terraform
cd terraform/networking
terraform init

# Preview changes
terraform plan

# Deploy infrastructure (costs ~$100/month for NAT Gateways)
terraform apply

# Destroy when done
terraform destroy
```

## AWS Services Used

- **VPC**: Network isolation
- **Subnets**: Public/private separation
- **Internet Gateway**: Public internet access
- **NAT Gateway**: Private subnet outbound access
- **Route Tables**: Traffic routing
- **Elastic IPs**: Static IPs for NAT Gateways

## Design Decisions

### Why Multi-Account?
- **Security blast radius**: Compromised dev account cannot affect production
- **Cost visibility**: Separate billing per environment
- **Compliance**: HIPAA requires clear separation of production data

### Why Transit Gateway? (Coming Next Phase)
- **Scalability**: Easier to add accounts than VPC peering mesh
- **Central management**: Single point of control for inter-account routing
- **Future-proof**: Supports 5,000 attachments Update README with security module documentationvs manual peering management

## Coming Next
- [x] Networking module (VPCs across 3 environments)
- [x] Security module (CloudTrail, GuardDuty, Security Hub, Config)
- [ ] IAM module (SCPs, Identity Center, RBAC)
- [ ] Transit Gateway for cross-account connectivity
- [ ] Cost analysis and optimization recommendations

*This is a portfolio project demonstrating Solutions Architect skills. Not deployed to production.*