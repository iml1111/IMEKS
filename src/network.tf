# https://github.com/terraform-aws-modules/terraform-aws-vpc
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  #version = "5.1.2"

  name                    = var.vpc_name
  map_public_ip_on_launch = true

  cidr = "10.0.0.0/16"
  azs  = ["${var.region}a", "${var.region}c"]

  public_subnets  = ["10.0.0.0/19", "10.0.32.0/19"]
  private_subnets = ["10.0.96.0/19", "10.0.128.0/19"]
  intra_subnets   = ["10.0.192.0/20", "10.0.208.0/20"]

  # Check at Production
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true

  # Check at Production
  enable_flow_log                      = true
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
    "karpenter.sh/discovery"                    = var.cluster_name
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = 1
    "karpenter.sh/discovery"                    = var.cluster_name
  }
  vpc_tags = {
    Name                                        = var.vpc_name
    Stage                                       = var.stage
    Author                                      = local.author
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
  tags = {
    Name   = var.vpc_name
    Stage  = var.stage
    Author = local.author
  }
}


# VPC Additional Security Group
resource "aws_security_group" "additional" {
  name        = "${var.cluster_name}-additional"
  vpc_id      = module.vpc.vpc_id
  description = "EKS Additional security group"
  # SSH Internal Facing
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
  tags = {
    Name   = "${var.cluster_name}-additional-sg"
    Stage  = var.stage
    Author = local.author
  }
}


# VPC Endpoints
module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  #version = "5.1.2"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [data.aws_security_group.default.id]

  endpoints = {
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      tags = {
        Name   = "${var.vpc_name}-s3-vpc-endpoint"
        Stage  = var.stage
        Author = local.author
      }
    }
  }
}