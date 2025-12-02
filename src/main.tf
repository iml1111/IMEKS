# =============================================================================
# Main Terraform Configuration - EKS Infrastructure Orchestration
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Module
# -----------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  name            = local.vpc_name
  cidr            = var.vpc_cidr
  azs             = local.azs
  private_subnets = local.private_subnet_cidrs
  public_subnets  = local.public_subnet_cidrs

  single_nat_gateway = var.single_nat_gateway

  # EKS Subnet Tags
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# EKS Module
# -----------------------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  tags = local.common_tags

  depends_on = [module.vpc]
}

# -----------------------------------------------------------------------------
# Addons Module
# -----------------------------------------------------------------------------
module "addons" {
  source = "./modules/addons"

  cluster_name                       = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  oidc_provider_arn                  = module.eks.oidc_provider_arn
  oidc_provider_url                  = module.eks.oidc_provider_url

  vpc_id = module.vpc.vpc_id
  region = var.aws_region

  tags = local.common_tags

  depends_on = [module.eks]
}
