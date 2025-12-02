# =============================================================================
# Addons Module Outputs
# =============================================================================

# ALB Controller IRSA
output "alb_controller_role_arn" {
  description = "ARN of the ALB Controller IAM role"
  value       = module.alb_controller_irsa.arn
}

output "alb_controller_role_name" {
  description = "Name of the ALB Controller IAM role"
  value       = module.alb_controller_irsa.name
}

# Metrics Server
output "metrics_server_release_name" {
  description = "Metrics Server Helm release name"
  value       = helm_release.metrics_server.name
}

output "metrics_server_release_status" {
  description = "Metrics Server Helm release status"
  value       = helm_release.metrics_server.status
}

# AWS Load Balancer Controller
output "alb_controller_release_name" {
  description = "AWS Load Balancer Controller Helm release name"
  value       = helm_release.aws_load_balancer_controller.name
}

output "alb_controller_release_status" {
  description = "AWS Load Balancer Controller Helm release status"
  value       = helm_release.aws_load_balancer_controller.status
}
