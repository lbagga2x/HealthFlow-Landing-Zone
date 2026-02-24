variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "organization_id" {
  description = "AWS Organization ID (format: o-xxxxxxxxxx)"
  type        = string
}

variable "organization_root_id" {
  description = "AWS Organization root ID (format: r-xxxx)"
  type        = string
}

variable "allowed_regions" {
  description = "List of AWS regions allowed for resource creation"
  type        = list(string)
  default     = ["us-east-1", "us-west-2"]
}

variable "enable_scp_cloudtrail_protection" {
  description = "Enable SCP to prevent CloudTrail deletion"
  type        = bool
  default     = true
}

variable "enable_scp_encryption_enforcement" {
  description = "Enable SCP to require encryption"
  type        = bool
  default     = true
}

variable "enable_scp_region_restriction" {
  description = "Enable SCP to restrict regions"
  type        = bool
  default     = true
}

variable "enable_scp_public_s3_block" {
  description = "Enable SCP to block public S3 buckets"
  type        = bool
  default     = true
}

variable "enable_scp_mfa_requirement" {
  description = "Enable SCP to require MFA"
  type        = bool
  default     = true
}