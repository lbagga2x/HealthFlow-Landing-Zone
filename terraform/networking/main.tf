# DEV VPC
module "dev_vpc" {
  source = "../modules/vpc"

  vpc_name    = "dev"
  environment = "dev"
  vpc_cider   = var.dev_vpc_cidr

  public_subnet_cidr  = ["10.3.1.0/24", "10.3.2.0/24"]
  private_subnet_cidr = ["10.3.3.0/24", "10.3.4.0/24"]
  availability_zones  = var.availability_zones
}

# Staging VPC
module "staging_vpc" {
  source = "../modules/vpc"

  vpc_name    = "staging"
  environment = "staging"
  vpc_cider   = var.staging_vpc_cidr

  public_subnet_cidr  = ["10.4.1.0/24", "10.4.2.0/24"]
  private_subnet_cidr = ["10.4.3.0/24", "10.4.4.0/24"]
  availability_zones  = var.availability_zones
}

# Production VPC
module "prod_vpc" {
  source = "../modules/vpc"

  vpc_name    = "prod"
  environment = "prod"
  vpc_cider   = var.prod_vpc_cidr

  public_subnet_cidr  = ["10.5.1.0/24", "10.5.2.0/24"]
  private_subnet_cidr = ["10.5.3.0/24", "10.5.4.0/24"]
  availability_zones  = var.availability_zones
}