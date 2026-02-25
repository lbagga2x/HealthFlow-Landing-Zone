# Transit Gateway Architecture Decision Record

**Project:** HealthFlow AWS Landing Zone  
**Date:** February 2026  
**Status:** Designed (Not Deployed)  
**Decision Owner:** Platform Team

---

## Context

HealthFlow is implementing a multi-account AWS architecture with separate accounts for Dev, Staging, and Production environments. As the organization scales from 5 to 50 engineers over 2 years, cross-account connectivity requirements will increase.

**Current State:**
- 3 VPCs (Dev: 10.3.0.0/16, Staging: 10.4.0.0/16, Prod: 10.5.0.0/16)
- No cross-account connectivity
- Engineers cannot access resources across environments (e.g., Dev cannot query Staging DB for testing)

**Future Requirements:**
- Developers need read-only access to Staging for troubleshooting
- CI/CD pipelines need to deploy from Shared Services account to all environments
- Centralized logging aggregation from all accounts to Security account
- Likely addition of 3-5 more accounts as organization grows

---

## Decision

**We will implement AWS Transit Gateway as the central connectivity hub for all VPCs.**

---

## Options Considered

### Option 1: VPC Peering

**How it works:**
- Direct connection between two VPCs
- One peering connection per VPC pair

**Pros:**
- ✅ Free (no hourly charge)
- ✅ Low latency (direct connection)
- ✅ Simple for 2-3 VPCs

**Cons:**
- ❌ Non-transitive (if A peers with B, and B peers with C, A cannot reach C)
- ❌ Scales poorly (N VPCs = N×(N-1)/2 connections)
  - 3 VPCs = 3 peering connections
  - 6 VPCs = 15 peering connections
  - 10 VPCs = 45 peering connections
- ❌ Complex route table management (each VPC needs routes to all others)
- ❌ Error-prone (manual setup for each connection)
- ❌ Difficult to audit (which VPCs can talk to which?)

**Cost for HealthFlow:**
- Base: $0/month
- Data transfer: $0.01/GB (same as Transit Gateway)
- **Total: $0/month** (excluding data transfer)

---

### Option 2: Transit Gateway (Selected)

**How it works:**
- Central hub-and-spoke model
- Each VPC attaches to Transit Gateway once
- Transit Gateway handles routing between all VPCs

**Pros:**
- ✅ Scales linearly (10 VPCs = 10 attachments, not 45 peering connections)
- ✅ Centralized routing (one route table to manage)
- ✅ Transitive routing (A can reach C through Transit Gateway)
- ✅ Simple to add new VPCs (one attachment, automatic routing)
- ✅ Built-in route table isolation (can prevent Dev → Prod if needed)
- ✅ Supports future features:
  - Centralized network inspection (firewall in the middle)
  - VPN connectivity (on-premise to all VPCs via one connection)
  - Inter-region peering (multi-region architecture)
- ✅ Clear security posture (easy to audit what connects to what)

**Cons:**
- ❌ Costs ~$144/month for 3 VPCs ($36 base + 3×$36 attachments)
- ❌ Slight additional latency vs direct peering (~1-2ms)
- ❌ More complex initial setup

**Cost for HealthFlow:**
- Transit Gateway: $0.05/hour × 720 hours = $36/month
- Dev attachment: $0.05/hour × 720 hours = $36/month
- Staging attachment: $0.05/hour × 720 hours = $36/month
- Prod attachment: $0.05/hour × 720 hours = $36/month
- Data processing: $0.02/GB (same as peering)
- **Total: ~$144/month** (excluding data transfer)

---

### Option 3: AWS PrivateLink

**How it works:**
- Service-specific connections
- Expose specific services (like an API endpoint) across VPCs

**Pros:**
- ✅ Granular control (expose only specific services)
- ✅ No IP overlap concerns

**Cons:**
- ❌ Not suitable for general VPC-to-VPC connectivity
- ❌ Complex for multiple services
- ❌ Higher cost per endpoint ($0.01/hour per endpoint + data)
- ❌ Only works for specific services, not general networking

**Use case:** Exposing a single API, not full VPC connectivity

**Not suitable for HealthFlow's requirements.**

---

## Decision Rationale

**We chose Transit Gateway despite the cost because:**

### 1. **Operational Simplicity**

**Engineering time cost:**
```
VPC Peering management with 6 VPCs:
- 15 peering connections to create
- 15 × 2 = 30 route table updates (each VPC needs routes to others)
- Time to add 7th VPC: ~30 minutes (create 6 new connections, update routes)

DevOps engineer hourly rate: ~$150/hour
Monthly overhead: ~2 hours = $300/month in labor

Transit Gateway:
- Time to add 7th VPC: ~5 minutes (one attachment, routes auto-propagate)
- Monthly overhead: ~15 minutes = $37.50/month in labor

Labor savings: $262.50/month
TGW cost: $144/month
Net: Still cheaper when factoring in engineering time
```

### 2. **Scalability**

**HealthFlow's growth trajectory:**
```
Current: 3 accounts (Dev, Staging, Prod)
6 months: +2 accounts (Security, Shared Services) = 5 total
1 year: +2 accounts (Data, Compliance) = 7 total
2 years: +3 accounts (Regional deployments) = 10 total

VPC Peering at 10 accounts:
- 45 peering connections
- 90+ route table updates
- Unmaintainable

Transit Gateway at 10 accounts:
- 10 attachments
- Centralized routing
- Still simple
```

### 3. **Cost at Scale**
```
VPC Peering:
- 3 VPCs: $0 + labor ($300/mo) = $300/month
- 10 VPCs: $0 + labor ($800/mo) = $800/month

Transit Gateway:
- 3 VPCs: $144 + labor ($37/mo) = $181/month ← cheaper
- 10 VPCs: $396 + labor ($37/mo) = $433/month ← cheaper
```

**Transit Gateway is cheaper at scale when including engineering time.**

### 4. **Security & Compliance**

**HIPAA compliance benefits:**
- Centralized audit point (all inter-VPC traffic flows through one place)
- Easy to enable VPC Flow Logs on Transit Gateway
- Clear security boundaries (one route table to review)
- Can easily add network inspection layer later (firewall in Transit Gateway)

**Incident response:**
```
Security incident in Dev VPC:

With VPC Peering:
"Which VPCs can reach Dev? Let me check 15 peering connections..."
Takes 10 minutes to figure out

With Transit Gateway:
"Check Transit Gateway route table"
Immediately see: Dev can reach Staging, Prod, Shared Services
Can instantly disable routes if needed
```

### 5. **Future-Proofing**

**Planned features Transit Gateway enables:**
- **VPN connectivity:** On-premise office → Transit Gateway → all VPCs
  - vs VPN to each VPC individually (expensive, complex)
- **Centralized egress:** All internet traffic through one VPC (cost optimization)
- **Network firewall:** Inspection of all inter-VPC traffic in one place
- **Multi-region:** Transit Gateway peering for DR in us-west-2

**None of these are possible with VPC Peering.**

---

## Implementation Plan

### Phase 1: Core Infrastructure (Current)
✅ Create VPCs with proper CIDR planning (no overlaps)  
✅ Document Transit Gateway design  
⏳ Validate Terraform code (syntax check only)

### Phase 2: Transit Gateway Deployment (Future)
- Deploy Transit Gateway in Shared Services account
- Attach Dev, Staging, Prod VPCs
- Update VPC route tables to route cross-account traffic to TGW
- Test connectivity (Dev → Staging ping test)
- Enable VPC Flow Logs on Transit Gateway
- Document runbook for adding new VPC attachments

### Phase 3: Advanced Features (6-12 months)
- Add VPN connection for on-premise access
- Implement centralized egress VPC (cost optimization)
- Enable Transit Gateway Network Manager (monitoring)
- Add firewall inspection VPC if needed

---

## Risks & Mitigations

### Risk 1: Cost Overrun
**Risk:** Transit Gateway costs more than budgeted

**Mitigation:**
- Monthly cost: $144 is 2.8% of $5K infrastructure budget (acceptable)
- CloudWatch billing alerts set at $200/month
- Cost is predictable (fixed hourly rate, not usage-based)

### Risk 2: Misconfiguration
**Risk:** Wrong route configuration breaks connectivity

**Mitigation:**
- Infrastructure as Code (Terraform) prevents manual errors
- Peer review required for Transit Gateway changes
- Test in Dev account first before Staging/Prod
- Enable VPC Flow Logs to troubleshoot routing issues

### Risk 3: Single Point of Failure
**Risk:** Transit Gateway outage affects all cross-account traffic

**Mitigation:**
- Transit Gateway is AWS-managed (99.95% SLA)
- Multi-AZ by default (automatic failover)
- Applications should handle temporary connectivity loss gracefully
- Not a concern: If TGW fails, AWS has bigger problems (region-wide outage)

---

## Success Metrics

**We will consider Transit Gateway successful if:**

1. **Connectivity works:** Dev can query Staging database (latency < 5ms)
2. **Easy to scale:** Adding 4th VPC takes < 10 minutes
3. **Cost controlled:** Monthly TGW costs stay under $200 for first year
4. **Audit compliance:** Security team can trace all inter-VPC traffic
5. **Zero outages:** No production incidents caused by TGW misconfiguration

---

## Alternatives Reconsidered

**When would we switch back to VPC Peering?**

Only if:
- HealthFlow stops growing (stays at 3 VPCs forever) ← unlikely
- AND engineering time is free ← unrealistic
- AND we never need VPN/multi-region/firewall ← unlikely

**Probability of reverting decision: < 5%**

---

## References

- [AWS Transit Gateway Pricing](https://aws.amazon.com/transit-gateway/pricing/)
- [AWS Transit Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/tgw/)
- [VPC Peering vs Transit Gateway Comparison](https://docs.aws.amazon.com/whitepapers/latest/aws-vpc-connectivity-options/aws-transit-gateway.html)
- HealthFlow Infrastructure Budget (internal)

---