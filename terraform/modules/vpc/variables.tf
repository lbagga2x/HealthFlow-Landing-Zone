variable "vpc_name" {
  description = "Name of the VPC (e.g. dev, staging, prod)"
  type = string
}

variable "vpc_cider" {
  description = "IP range for VPC (e.g. 10.3.0.0/16)"
  type = string
}

variable "environment" {
    description = "Which environment is this for? (e.g. dev, staging, prod)"
    type = string

    validation {
      condition = contains(["dev", "staging", "prod"], var.environment)
      error_message = "Environment must be dev, staging or prod."
    }
}

variable "private_subnet_cidr" {
  description = "List of IP ranges for private subnet"
  type = list(string)
}

variable "public_subnet_cidr" {
  description = "List of IP ranges for public subnet"
  type = list(string)
}

variable "availability_zones" {
  description = "List of aws availability zones to use"
  type = list(string)
}


