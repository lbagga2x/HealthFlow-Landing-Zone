variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "transit_gateway_name" {
  description = "Name of the Transit Gateway"
  type        = string
  default     = "healthflow-tgw"
}

variable "transit_gateway_description" {
  description = "Description of the Transit Gateway"
  type        = string
  default     = "HealthFlow multi-account Transit Gateway for cross-account connectivity"
}

variable "enable_dns_support" {
  description = "Enable DNS support for Transit Gateway"
  type        = bool
  default     = true
}

variable "enable_auto_accept_shared_attachments" {
  description = "Automatically accept shared attachments from other accounts"
  type        = bool
  default     = false
}

variable "amazon_side_asn" {
  description = "Private Autonomous System Number (ASN) for the Amazon side of BGP session"
  type        = number
  default     = 64512
}

# VPC attachment variables
variable "dev_vpc_id" {
  description = "ID of Dev VPC to attach"
  type        = string
  default     = ""
}

variable "dev_subnet_ids" {
  description = "List of Dev VPC subnet IDs for TGW attachment"
  type        = list(string)
  default     = []
}

variable "staging_vpc_id" {
  description = "ID of Staging VPC to attach"
  type        = string
  default     = ""
}

variable "staging_subnet_ids" {
  description = "List of Staging VPC subnet IDs for TGW attachment"
  type        = list(string)
  default     = []
}

variable "prod_vpc_id" {
  description = "ID of Production VPC to attach"
  type        = string
  default     = ""
}

variable "prod_subnet_ids" {
  description = "List of Production VPC subnet IDs for TGW attachment"
  type        = list(string)
  default     = []
}