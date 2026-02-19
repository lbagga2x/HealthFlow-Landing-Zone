variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "organization_id" {
  description = "AWS Organization ID (format: o-xxxxxxxxxx)"
  type        = string
  default     = ""
}

variable "cloud_trail_log_retention_days" {
  description = "How long to keep CloudTrail logs in S3"
  type        = number
  default     = 365 # 1 year for HIPAA
}

variable "enable_guardduty" {
  description = "Enable GuardDuty threat detection"
  type        = bool
  default     = true
}

variable "enable_securityhub" {
  description = "Enable Security Hub compliance monitoring"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config resource tracking"
  type        = bool
  default     = true
}