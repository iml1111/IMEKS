# =============================================================================
# EKS Module
# =============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.10.1"

  name               = var.cluster_name
  kubernetes_version = var.cluster_version

  # VPC Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Cluster Endpoint Access
  endpoint_public_access  = var.cluster_endpoint_public_access
  endpoint_private_access = var.cluster_endpoint_private_access

  # Enable OIDC Provider for IRSA
  enable_irsa = true

  # Cluster Logging
  enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Cluster Addons
  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.arn
    }
  }

  # Managed Node Groups
  eks_managed_node_groups = {
    default = {
      create          = true
      name            = "${var.cluster_name}-default"
      use_name_prefix = false

      # Node Group Size
      min_size     = 1
      max_size     = 5
      desired_size = 2

      # Instance Configuration
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["c5.xlarge"]
      capacity_type  = "ON_DEMAND"

      # EBS Configuration
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      # IMDSv2 Enforcement
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      # Labels
      labels = {
        role = "general"
      }

      tags = var.tags
    }
  }

  # Enable cluster creator admin permissions
  enable_cluster_creator_admin_permissions = true

  # Access Entries (Hybrid: AWS policy for admin, K8s groups for RBAC)
  access_entries = var.access_entries

  tags = var.tags
}
