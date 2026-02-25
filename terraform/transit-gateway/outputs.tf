output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.arn
}

output "transit_gateway_route_table_id" {
  description = "ID of the default Transit Gateway route table"
  value       = aws_ec2_transit_gateway.main.association_default_route_table_id
}

output "dev_attachment_id" {
  description = "ID of the Dev VPC attachment"
  value       = var.dev_vpc_id != "" ? aws_ec2_transit_gateway_vpc_attachment.dev[0].id : null
}

output "staging_attachment_id" {
  description = "ID of the Staging VPC attachment"
  value       = var.staging_vpc_id != "" ? aws_ec2_transit_gateway_vpc_attachment.staging[0].id : null
}

output "prod_attachment_id" {
  description = "ID of the Production VPC attachment"
  value       = var.prod_vpc_id != "" ? aws_ec2_transit_gateway_vpc_attachment.prod[0].id : null
}

output "transit_gateway_costs" {
  description = "Estimated monthly costs for Transit Gateway"
  value = {
    base_cost              = "$36/month (Transit Gateway itself)"
    per_attachment         = "$0.05/hour = ~$36/month per attachment"
    data_processing        = "$0.02/GB processed"
    estimated_total_3_vpcs = "~$144/month (TGW + 3 attachments, excluding data transfer)"
  }
}