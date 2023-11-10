output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "AWS VPC Name"
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "AWS VPC Name"
  value       = var.vpc_name
}

output "region" {
  description = "AWS region"
  value       = var.region
}
