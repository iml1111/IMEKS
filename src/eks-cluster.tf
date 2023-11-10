# EKS Cluster & NodeGroup
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  #version = "19.19.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      preserve    = true
      most_recent = true
      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
    aws-ebs-csi-driver = {
      preserve    = true
      most_recent = true
    }
  }

  # External encryption key
  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.kms.key_arn
  }

  iam_role_additional_policies = {
    additional                = aws_iam_policy.additional.arn
    ssm_managed_instance_core = data.aws_iam_policy.ssm_managed_instance_core.arn
    cloudwatch_agent_server   = data.aws_iam_policy.cloudwatch_agent_server.arn
    ebs_csi_driver_policy     = data.aws_iam_policy.ebs_csi_driver.arn
  }

  vpc_id = module.vpc.vpc_id
  subnet_ids = concat(
    module.vpc.private_subnets,
    module.vpc.public_subnets
  )
  control_plane_subnet_ids = module.vpc.intra_subnets

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description              = "Nodes on ephemeral ports"
      protocol                 = "tcp"
      from_port                = 1025
      to_port                  = 65535
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
    ingress_source_security_group_id = {
      description              = "Ingress from another computed security group"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      type                     = "ingress"
      source_security_group_id = aws_security_group.additional.id
    }
  }

  create_node_security_group = false

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type                              = "AL2_x86_64"
    attach_cluster_primary_security_group = true
    vpc_security_group_ids                = [aws_security_group.additional.id]
    iam_role_additional_policies = {
      additional                = aws_iam_policy.additional.arn
      ssm_managed_instance_core = data.aws_iam_policy.ssm_managed_instance_core.arn
      cloudwatch_agent_server   = data.aws_iam_policy.cloudwatch_agent_server.arn
      ebs_csi_driver_policy     = data.aws_iam_policy.ebs_csi_driver.arn
    }
  }

  eks_managed_node_groups = {
    frontend = {
      name           = "${var.eks_stage}-frontend"
      subnet_ids     = module.vpc.public_subnets
      instance_types = ["c5a.xlarge"]
      capacity_type  = "SPOT"

      min_size     = 1
      max_size     = 4
      desired_size = local.frontend_nodegroup_desired_size

      update_config = {
        max_unavailable_percentage = 33
      }

      labels = {
        nodegroup-type = "${var.eks_stage}-frontend"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = false
            delete_on_termination = true
          }
        }
      }

      tags = {
        Stage = var.stage
        Author = var.author
      }
    }

    backend = {
      name           = "${var.eks_stage}-backend"
      subnet_ids     = module.vpc.private_subnets
      instance_types = ["c5a.xlarge"]
      capacity_type  = "SPOT"

      min_size     = 1
      max_size     = 4
      desired_size = local.backend_nodegroup_desired_size

      update_config = {
        max_unavailable_percentage = 33
      }

      labels = {
        nodegroup-type = "${var.eks_stage}-backend"
      }

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            encrypted             = false
            delete_on_termination = true
          }
        }
      }

      tags = {
        Stage = var.stage
        Author = var.author
      }
    }
  }

  # OIDC Identity provider
  cluster_identity_providers = {
    sts = { client_id = "sts.amazonaws.com" }
  }

  manage_aws_auth_configmap = true

  aws_auth_users = [
    {
      # TODO: Use a variable for the username
      userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/terraform"
      username = "terraform"
      groups   = ["system:masters"]
    },
  ]

  aws_auth_accounts = [data.aws_caller_identity.current.account_id]

  tags = {
    "karpenter.sh/discovery" = var.cluster_name,
    Stage                    = var.stage
    Author                   = var.author
  }
}
# https://github.com/bryantbiggs/eks-desired-size-hack
resource "null_resource" "update_frontend_desired_size" {
  triggers = {
    desired_size = local.frontend_nodegroup_desired_size
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      aws eks update-nodegroup-config --cluster-name ${module.eks.cluster_name} --nodegroup-name ${element(split(":", module.eks.eks_managed_node_groups["frontend"].node_group_id), 1)} --scaling-config desiredSize=${local.frontend_nodegroup_desired_size}
    EOT
  }

  depends_on = [
    module.eks
  ]
}
resource "null_resource" "update_backend_desired_size" {
  triggers = {
    desired_size = local.backend_nodegroup_desired_size
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      aws eks update-nodegroup-config --cluster-name ${module.eks.cluster_name} --nodegroup-name ${element(split(":", module.eks.eks_managed_node_groups["backend"].node_group_id), 1)} --scaling-config desiredSize=${local.backend_nodegroup_desired_size}
    EOT
  }
  depends_on = [
    module.eks
  ]
}

resource "aws_iam_policy" "additional" {
  name = "${var.cluster_name}-additional"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = {
    Name   = "${var.cluster_name}-additional"
    Stage  = var.stage
    Author = var.author
  }
}

module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  #version = "2.1.0"

  aliases               = ["eks/${var.cluster_name}"]
  description           = "${var.cluster_name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]

  tags = {
    Name   = "${var.cluster_name}-kms"
    Stage  = var.stage
    Author = var.author
  }
}
