# =============================================================================
# VPC Flow Log Module
# =============================================================================
# Separated for v7.x compatibility
# See: https://github.com/terraform-aws-modules/terraform-aws-vpc

module "vpc_flow_log" {
  source  = "terraform-aws-modules/vpc/aws//modules/flow-log"
  version = "6.5.1"

  vpc_id = module.vpc.vpc_id

  # Traffic Configuration
  traffic_type             = "ALL"
  max_aggregation_interval = 600

  # CloudWatch Logs Destination
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_name              = "/aws/vpc-flow-log/${var.name}"
  cloudwatch_log_group_use_name_prefix   = false
  cloudwatch_log_group_retention_in_days = 30

  # IAM Role
  create_iam_role = true

  tags = var.tags
}
