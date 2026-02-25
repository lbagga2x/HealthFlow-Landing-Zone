# HealthFlow AWS Landing Zone - Cost Analysis

**Last Updated:** February 2026  
**Analysis Period:** Monthly recurring costs (baseline infrastructure only)  
**Excludes:** Application workload costs (EC2, RDS, Lambda for actual apps)

---

## Executive Summary

**Total Monthly Infrastructure Cost: $794 - $938**

This covers the foundational security, networking, and governance infrastructure required for HIPAA-compliant multi-account architecture. Application workload costs (databases, compute, storage) are additional.

**Cost Breakdown:**
- Networking: $240 (NAT Gateways, Transit Gateway)
- Security & Compliance: $394 (CloudTrail, GuardDuty, Security Hub, Config)
- Data Transfer: $100-244 estimate (depends on usage)
- IAM: $0 (SCPs are free)

**Budget Status:** Well within $5,000/month infrastructure budget (15.8% utilization)

---

## Detailed Cost Breakdown

### 1. Networking Infrastructure

| Service | Quantity | Unit Cost | Monthly Cost | Notes |
|---------|----------|-----------|--------------|-------|
| **NAT Gateway** | 3 (one per VPC) | $0.045/hour | **$97.20** | 3 × $0.045 × 720 hours |
| NAT Gateway Data Processing | Variable | $0.045/GB | $50-150 | Estimate: 1-3 TB/month |
| **Transit Gateway** | 1 | $0.05/hour | **$36.00** | $0.05 × 720 hours |
| Transit Gateway Attachments | 3 | $0.05/hour each | **$108.00** | 3 × $0.05 × 720 hours |
| Transit Gateway Data Processing | Variable | $0.02/GB | $20-40 | Estimate: 1-2 TB cross-account |
| **VPCs** | 3 | Free | $0.00 | No charge for VPCs |
| **Subnets** | 12 | Free | $0.00 | No charge for subnets |
| **Route Tables** | 6 | Free | $0.00 | No charge for route tables |
| **Internet Gateways** | 3 | Free | $0.00 | No charge for IGW |
| **Elastic IPs** (NAT) | 3 | Free | $0.00 | Free when attached to running resource |
| | | **Subtotal:** | **$311.20 + data transfer** | |

**Networking Total: $311 - $461/month** (depending on data transfer volume)

---

### 2. Security & Compliance

| Service | Quantity | Unit Cost | Monthly Cost | Notes |
|---------|----------|-----------|--------------|-------|
| **CloudTrail** | 1 org trail | First trail free | **$0.00** | Organization trail (first trail free) |
| CloudTrail Data Events | ~1M events | $0.10/100K events | **$1.00** | S3 data events only |
| CloudTrail Log Storage (S3) | ~50 GB | $0.023/GB | **$1.15** | 50 GB × $0.023 |
| CloudTrail Log Storage (Glacier after 90 days) | ~500 GB | $0.004/GB | **$2.00** | Deep archive |
| **GuardDuty** | 6 accounts | Base cost | **$4.60** | $0.76 × 6 accounts (first 30 days free) |
| GuardDuty CloudTrail Analysis | ~10M events | $4.60/million events | **$46.00** | 10M × $4.60 |
| GuardDuty VPC Flow Log Analysis | ~100 GB | $1.15/GB for first 500GB | **$115.00** | 100 GB × $1.15 |
| GuardDuty DNS Log Analysis | ~5M queries | $0.46/million queries | **$2.30** | 5M × $0.46 |
| GuardDuty S3 Protection | ~1 TB analyzed | $0.80/1000 GB | **$0.80** | S3 data event analysis |
| GuardDuty Malware Protection | ~5 scans | $0.10/GB scanned | **$1.00** | Triggered on findings only |
| **Security Hub** | 6 accounts | Free for first 10K checks | **$0.00** | Under free tier |
| Security Hub Checks | ~50K/month | $0.0010/check after 10K | **$40.00** | 40K × $0.001 |
| Security Hub Findings Ingestion | ~1K findings | $0.00003/finding | **$0.03** | Minimal cost |
| **AWS Config** | ~50 resources | $0.003/config item | **$108.00** | 50 resources × 24 snapshots/day × 30 days × $0.003 |
| Config Rules | 10 rules | $0.001/evaluation | **$36.00** | 10 rules × 50 resources × 24 × 30 × $0.001 |
| Config S3 Storage | ~20 GB | $0.023/GB | **$0.46** | Configuration snapshots |
| | | **Subtotal:** | **$358.34** | |

**Security Total: $358/month**

**Optional Security Enhancements (Not Currently Enabled):**
- AWS Firewall Manager: $100/month (centralized firewall management)
- AWS WAF: $5 + $1/rule + $0.60/million requests
- AWS Shield Advanced: $3,000/month (DDoS protection)

---

### 3. IAM & Identity

| Service | Quantity | Unit Cost | Monthly Cost | Notes |
|---------|----------|-----------|--------------|-------|
| **Service Control Policies** | 5 policies | Free | **$0.00** | No charge for SCPs |
| **IAM Roles** | ~20 roles | Free | **$0.00** | No charge for IAM |
| **IAM Identity Center** | Not deployed | $0.00 + active users | **$0.00** | Would be free for <50 users |
| | | **Subtotal:** | **$0.00** | |

**IAM Total: $0/month** (IAM services are free)

---

### 4. Data Transfer Costs

| Traffic Type | Estimate | Unit Cost | Monthly Cost | Notes |
|--------------|----------|-----------|--------------|-------|
| **Outbound to Internet** (NAT Gateway) | 500 GB | $0.09/GB | **$45.00** | Software updates, API calls |
| **Cross-Account** (Transit Gateway) | 1 TB | $0.02/GB | **$20.00** | Dev ↔ Staging traffic |
| **Inbound from Internet** | Any amount | Free | **$0.00** | Ingress is free |
| **Same-AZ transfers** | Any amount | Free | **$0.00** | Within same AZ |
| | | **Subtotal:** | **$65.00** | |

**Data Transfer Total: $65 - $120/month** (highly variable based on usage)

**Cost Optimization Opportunity:**
Using VPC Endpoints for S3 and DynamoDB could save $20-40/month in NAT Gateway data processing costs.

---

## Total Monthly Cost Summary

| Category | Low Estimate | High Estimate | Actual Expected |
|----------|--------------|---------------|-----------------|
| Networking | $311 | $461 | ~$380 |
| Security & Compliance | $358 | $358 | $358 |
| IAM | $0 | $0 | $0 |
| Data Transfer | $65 | $120 | $80 |
| **TOTAL** | **$734** | **$939** | **~$818** |

**Budget Utilization: 16.4% of $5,000 monthly budget**

---

## Cost Scaling Projections

### 6 Months (5 accounts total)

| Category | Current (3 VPCs) | 6 Months (5 VPCs) | Increase |
|----------|------------------|-------------------|----------|
| NAT Gateways | $97 | $162 | +$65 |
| Transit Gateway Attachments | $108 | $180 | +$72 |
| GuardDuty | $170 | $283 | +$113 |
| AWS Config | $144 | $240 | +$96 |
| **TOTAL** | **$818** | **$1,164** | **+$346** |

**Budget Utilization: 23% of $5K budget**

---

### 1 Year (7 accounts total)

| Category | Current (3 VPCs) | 1 Year (7 VPCs) | Increase |
|----------|------------------|-----------------|----------|
| NAT Gateways | $97 | $227 | +$130 |
| Transit Gateway Attachments | $108 | $252 | +$144 |
| GuardDuty | $170 | $397 | +$227 |
| AWS Config | $144 | $336 | +$192 |
| **TOTAL** | **$818** | **$1,511** | **+$693** |

**Budget Utilization: 30% of $5K budget**

---

### 2 Years (10 accounts total)

| Category | Current (3 VPCs) | 2 Years (10 VPCs) | Increase |
|----------|------------------|-------------------|----------|
| NAT Gateways | $97 | $324 | +$227 |
| Transit Gateway Attachments | $108 | $360 | +$252 |
| GuardDuty | $170 | $567 | +$397 |
| AWS Config | $144 | $480 | +$336 |
| **TOTAL** | **$818** | **$2,030** | **+$1,212** |

**Budget Utilization: 41% of $5K budget**

**Still comfortably within budget even at 10 accounts.**

---

## Cost Optimization Opportunities

### Immediate (0-3 months)

1. **VPC Endpoints for S3/DynamoDB**
   - Cost: $7.20/month per endpoint
   - Savings: $20-40/month in NAT Gateway data processing
   - Net savings: $12-3