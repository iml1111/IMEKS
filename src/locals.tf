# =============================================================================
# Local Values
# =============================================================================

locals {
  # Naming
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "${local.name_prefix}-eks"
  vpc_name     = "${local.name_prefix}-vpc"

  # Availability Zones
  azs = slice(data.aws_availability_zones.available.names, 0, var.availability_zones_count)

  # Subnet CIDR Calculation
  # /16 VPC -> /20 subnets (4096 IPs each)
  private_subnet_cidrs = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnet_cidrs  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + 4)]

  # Common Tags
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  # EKS Tags for Subnet Discovery
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"             = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}
