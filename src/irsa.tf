# https://github.com/terraform-aws-modules/terraform-aws-iam/tree/v5.30.1/modules/iam-role-for-service-accounts-eks
# version = 5.30.1

module "load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${var.eks_stage}-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Stage  = var.stage
    Author = var.author
  }
}

module "cert_manager_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                     = "${var.eks_stage}-cert-manager"
  attach_cert_manager_policy    = true
  cert_manager_hosted_zone_arns = ["arn:aws:route53:::hostedzone/IClearlyMadeThisUp"]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cert-manager"]
    }
  }

  tags = {
    Stage  = var.stage
    Author = var.author
  }
}

module "cluster_autoscaler_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                        = "${var.eks_stage}-cluster-autoscaler"
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks.cluster_name]

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }
  tags = {
    Stage  = var.stage
    Author = var.author
  }
}

module "ebs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${var.eks_stage}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = {
    Stage  = var.stage
    Author = var.author
  }
}

module "efs_csi_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "efs-csi"
  attach_efs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }
  role_policy_arns = {
    kms_encrytion_ebs_policy = aws_iam_policy.kms_encrytion_ebs.arn
  }

  tags = {
    Stage  = var.stage
    Author = var.author
  }
}

resource "aws_iam_policy" "kms_encrytion_ebs" {
  name        = var.kms_encryption_ebs_policy_name
  description = "${var.cluster_name} KMS Encryption EBS IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
    ]
  })

  tags = {
    Stage  = var.stage
    Author = var.author
  }
}

module "vpc_cni_ipv4_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name             = "${var.eks_stage}-vpc-cni-ipv4"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = {
    Stage  = var.stage
    Author = var.author
  }
}

module "fluent_bit_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = var.fluent_bit_iam_role_policy_name
  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["fluent-bit:fluent-bit"]
    }
  }
  role_policy_arns = {
    fluent_bit_policy = aws_iam_policy.fluent_bit.arn
  }
  tags = {
    Stage  = var.stage
    Author = var.author
  }
}

resource "aws_iam_policy" "fluent_bit" {
  name        = var.fluent_bit_iam_role_policy_name
  description = "${var.cluster_name} Fluent Bit IAM Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # AWS Elasticsearch Service Policy
      {
        Effect = "Allow"
        Action = [
          "es:ESHttp*",
        ]

        Resource = "arn:aws:es:${var.region}:${data.aws_caller_identity.current.account_id}:domain/*"
      },
      # AWS CloudWatch Policy
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/*"
      }
    ]
  })

  tags = {
    Stage  = var.stage
    Author = var.author
  }
}
