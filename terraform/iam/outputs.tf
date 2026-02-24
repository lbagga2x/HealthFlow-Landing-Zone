output "scp_cloudtrail_protection_id" {
  description = "ID of the CloudTrail protection SCP"
  value       = var.enable_scp_cloudtrail_protection ? aws_organizations_policy.prevent_cloudtrail_deletion[0].id : null
}

output "scp_encryption_enforcement_id" {
  description = "ID of the encryption enforcement SCP"
  value       = var.enable_scp_encryption_enforcement ? aws_organizations_policy.require_encryption[0].id : null
}

output "scp_region_restriction_id" {
  description = "ID of the region restriction SCP"
  value       = var.enable_scp_region_restriction ? aws_organizations_policy.restrict_regions[0].id : null
}

output "scp_public_s3_block_id" {
  description = "ID of the public S3 blocking SCP"
  value       = var.enable_scp_public_s3_block ? aws_organizations_policy.block_public_s3[0].id : null
}

output "scp_mfa_requirement_id" {
  description = "ID of the MFA requirement SCP"
  value       = var.enable_scp_mfa_requirement ? aws_organizations_policy.require_mfa[0].id : null
}

output "organization_id" {
  description = "AWS Organization ID"
  value       = data.aws_organizations_organization.main.id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = data.aws_organizations_organization.main.arn
}

output "enabled_scps" {
  description = "List of enabled SCPs"
  value = {
    cloudtrail_protection  = var.enable_scp_cloudtrail_protection
    encryption_enforcement = var.enable_scp_encryption_enforcement
    region_restriction     = var.enable_scp_region_restriction
    public_s3_block        = var.enable_scp_public_s3_block
    mfa_requirement        = var.enable_scp_mfa_requirement
  }
}