# TRANSIT GATEWAY
# ─────────────────────────────────────────

resource "aws_ec2_transit_gateway" "main" {
  description                     = var.transit_gateway_description
  amazon_side_asn                 = var.amazon_side_asn
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  dns_support                     = var.enable_dns_support ? "enable" : "disable"
  auto_accept_shared_attachments  = var.enable_auto_accept_shared_attachments ? "enable" : "disable"

  tags = {
    Name        = var.transit_gateway_name
    Purpose     = "cross-account-connectivity"
    Environment = "shared"
  }
}

# VPC ATTACHMENTS
# ─────────────────────────────────────────

# Dev VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  count = var.dev_vpc_id != "" ? 1 : 0

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.dev_vpc_id
  subnet_ids         = var.dev_subnet_ids

  dns_support                                     = "enable"
  ipv6_support                                    = "disable"
  appliance_mode_support                          = "disable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name        = "${var.transit_gateway_name}-dev-attachment"
    Environment = "dev"
    VPC         = "dev"
  }
}

# Staging VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "staging" {
  count = var.staging_vpc_id != "" ? 1 : 0

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.staging_vpc_id
  subnet_ids         = var.staging_subnet_ids

  dns_support                                     = "enable"
  ipv6_support                                    = "disable"
  appliance_mode_support                          = "disable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name        = "${var.transit_gateway_name}-staging-attachment"
    Environment = "staging"
    VPC         = "staging"
  }
}

# Production VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  count = var.prod_vpc_id != "" ? 1 : 0

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.prod_vpc_id
  subnet_ids         = var.prod_subnet_ids

  dns_support                                     = "enable"
  ipv6_support                                    = "disable"
  appliance_mode_support                          = "disable"
  transit_gateway_default_route_table_association = true
  transit_gateway_default_route_table_propagation = true

  tags = {
    Name        = "${var.transit_gateway_name}-prod-attachment"
    Environment = "prod"
    VPC         = "prod"
  }
}

# ─────────────────────────────────────────
# ROUTE TABLE UPDATES (VPC → Transit Gateway)
# ─────────────────────────────────────────

# These would typically be in a separate module that configures VPCs
# For now, we're documenting the required routes

# Example route that would be added to Dev VPC route tables:
# resource "aws_route" "dev_to_staging" {
#   route_table_id         = var.dev_private_route_table_id
#   destination_cidr_block = "10.4.0.0/16"  # Staging VPC CIDR
#   transit_gateway_id     = aws_ec2_transit_gateway.main.id
#   depends_on             = [aws_ec2_transit_gateway_vpc_attachment.dev]
# }

# Example route that would be added to Dev VPC route tables:
# resource "aws_route" "dev_to_prod" {
#   route_table_id         = var.dev_private_route_table_id
#   destination_cidr_block = "10.5.0.0/16"  # Prod VPC CIDR
#   transit_gateway_id     = aws_ec2_transit_gateway.main.id
#   depends_on             = [aws_ec2_transit_gateway_vpc_attachment.dev]
# }
# ```

# ---

## Why Commented Out?

# **The problem:** These routes belong in the VPC module, not the Transit Gateway module.
# ```
# Bad separation:
#   transit-gateway module modifies VPC route tables
#   → tight coupling between modules
#   → hard to maintain

# Good separation:
#   transit-gateway module creates TGW + attachments
#   networking module adds routes to VPC route tables
#   → clean module boundaries
#   → easy to understand