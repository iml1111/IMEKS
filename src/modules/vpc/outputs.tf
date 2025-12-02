# =============================================================================
# VPC Module Outputs
# =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets_cidr_blocks" {
  description = "List of private subnet CIDR blocks"
  value       = module.vpc.private_subnets_cidr_blocks
}

output "public_subnets_cidr_blocks" {
  description = "List of public subnet CIDR blocks"
  value       = module.vpc.public_subnets_cidr_blocks
}

output "nat_public_ips" {
  description = "List of NAT Gateway public IPs"
  value       = module.vpc.nat_public_ips
}

output "azs" {
  description = "List of availability zones used"
  value       = module.vpc.azs
}

# Flow Log Outputs
output "flow_log_id" {
  description = "VPC Flow Log ID"
  value       = module.vpc_flow_log.id
}

output "flow_log_cloudwatch_log_group_arn" {
  description = "CloudWatch Log Group ARN for VPC Flow Logs"
  value       = module.vpc_flow_log.cloudwatch_log_group_arn
}
