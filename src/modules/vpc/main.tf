# =============================================================================
# VPC Module
# =============================================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.1"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  # NAT Gateway Configuration
  enable_nat_gateway     = true
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = !var.single_nat_gateway

  # DNS Configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnet Tags for EKS
  private_subnet_tags = var.private_subnet_tags
  public_subnet_tags  = var.public_subnet_tags

  tags = var.tags
}
