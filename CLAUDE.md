# IMEKS Project Context

## Project Overview

AWS EKS Terraform boilerplate for production-ready Kubernetes infrastructure deployment.

## Architecture

```
src/
├── main.tf           # Orchestrates VPC → EKS → Addons
├── modules/
│   ├── vpc/          # terraform-aws-modules/vpc/aws v6.5.1
│   ├── eks/          # terraform-aws-modules/eks/aws v21.10.1
│   └── addons/       # Metrics Server + ALB Controller (IRSA)
└── helm_values/      # Helm chart configurations

assets/terraform_backend/  # S3 + DynamoDB for remote state
```

## Key Design Decisions

1. **IRSA Implementation**: Using `terraform-aws-modules/iam/aws v6.2.3` submodule (`iam-role-for-service-accounts`) since EKS module v21.x removed native IRSA support

2. **Node Groups**: Single managed node group (`main`) with:
   - AL2023 AMI
   - Private subnets only
   - IMDSv2 enforced
   - EBS encryption enabled

3. **Addons**: Always enabled (no toggle variables)
   - Metrics Server (chart 3.12.2)
   - AWS Load Balancer Controller (chart 1.16.0)

4. **Naming Constraint**: `project_name` max 9 characters (AWS IAM role name limit: 38 chars)

## Module Dependencies

```
VPC → EKS → Addons
         ↘ IRSA (ALB Controller)
```

## Version Constraints

- Terraform: >= 1.5.0
- AWS Provider: ~> 6.0
- Kubernetes Provider: ~> 2.38
- Helm Provider: ~> 3.1 (uses `kubernetes = {}` syntax, not block)

## Common Tasks

### Add New Addon
1. Create IRSA role in `src/modules/addons/irsa.tf`
2. Add Helm release in `src/modules/addons/<addon>.tf`
3. Create values file in `src/helm_values/`
4. Export outputs in `src/modules/addons/outputs.tf`

### Modify Node Group
Edit `src/modules/eks/main.tf` → `eks_managed_node_groups` block

### Change Network CIDR
Update `vpc_cidr` in `terraform.tfvars` and adjust `local.private_subnet_cidrs` / `local.public_subnet_cidrs` in `src/locals.tf` if needed

## Files to Update Together

- `src/variables.tf` ↔ `src/terraform.tfvars.example` (sync variable definitions)
- `src/modules/*/variables.tf` ↔ `src/main.tf` (module inputs)
- `src/modules/*/outputs.tf` ↔ `src/outputs.tf` (output propagation)

## Known Gotchas

- **Helm 3.x syntax**: Use `kubernetes = { ... }` not `kubernetes { ... }` block
- **IAM module v6.x**: Output names are `arn`, `name` (not `iam_role_arn`, `iam_role_name`)
- **EKS module v21.x**: Variable names changed (e.g., `name` not `cluster_name`, `kubernetes_version` not `cluster_version`)
