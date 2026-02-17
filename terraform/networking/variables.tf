variable "aws_region" {
  description = "AWS region to deploy into"
  type = string
  default = "us-east-2"
}

variable "dev_vpc_cidr" {
  description = "CIDR block for Dev VPC"
  type        = string
  default     = "10.3.0.0/16"
}

variable "staging_vpc_cidr" {
  description = "CIDR block for Staging VPC"
  type        = string
  default     = "10.4.0.0/16"
}

variable "prod_vpc_cidr" {
  description = "CIDR block for Prod VPC"
  type        = string
  default     = "10.5.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type = list(string)
  default = [ "us-east-1a", "us-east-1b" ]
}