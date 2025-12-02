# =============================================================================
# Local Values
# =============================================================================

locals {
  # Naming
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = local.name_prefix
  vpc_name     = local.name_prefix

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

  # =============================================================================
  # EKS Access Entries (Hybrid: Access Entries + RBAC)
  # =============================================================================

  # ARN prefix for dynamic construction
  iam_arn_prefix = "arn:aws:iam::${data.aws_caller_identity.current.account_id}"

  # Admin: AWS 정책으로 즉시 권한 부여
  admin_access_entries = {
    for idx, principal in var.eks_admin_principals : "admin-${idx}" => {
      principal_arn = "${local.iam_arn_prefix}:${principal}"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  # 일반 사용자: K8s 그룹 매핑만 (RBAC에서 권한 제어)
  user_access_entries = {
    for k, v in var.eks_access_entries : k => {
      principal_arn     = "${local.iam_arn_prefix}:${v.principal}"
      kubernetes_groups = v.kubernetes_groups
    }
  }

  # 병합
  all_access_entries = merge(
    local.admin_access_entries,
    local.user_access_entries
  )
}
