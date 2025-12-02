# IMEKS Project Context

## Project Overview

AWS EKS Terraform boilerplate for production-ready Kubernetes infrastructure deployment.

## Architecture

```
src/
├── main.tf           # Orchestrates VPC → EKS → Addons
├── modules/
│   ├── vpc/          # terraform-aws-modules/vpc/aws v6.5.1
│   │   ├── main.tf
│   │   ├── flow-log.tf    # Standalone flow-log module (v7.x ready)
│   │   └── outputs.tf
│   ├── eks/          # terraform-aws-modules/eks/aws v21.10.1
│   │   ├── main.tf
│   │   ├── irsa.tf        # EBS CSI Driver IRSA
│   │   └── outputs.tf
│   └── addons/       # Metrics Server + ALB Controller (IRSA)
└── helm_values/

scripts/              # Deployment/cleanup scripts
assets/terraform_backend/  # S3 + DynamoDB for remote state
```

## Key Design Decisions

1. **IRSA Implementation**: Using `terraform-aws-modules/iam/aws v6.2.3` submodule (`iam-role-for-service-accounts`)

2. **Node Groups**: Single managed node group (`default`) - hardcoded settings:
   - AL2023 AMI, c5.xlarge, ON_DEMAND
   - min/max/desired: 1/5/2, disk: 50GB
   - Private subnets only, IMDSv2 enforced

3. **Cluster Addons** (EKS managed):
   - coredns, kube-proxy, vpc-cni
   - aws-ebs-csi-driver (IRSA enabled)

4. **Helm Addons**:
   - Metrics Server (chart 3.13.0)
   - AWS Load Balancer Controller (chart 1.16.0)

5. **Naming Convention**: `{project_name}-{environment}` (max 9 chars for project_name)

6. **VPC Flow Log**: Separated to `flow-log.tf` for v7.x compatibility

## Module Dependencies

```
VPC → EKS → Addons
 │      ↘ EBS CSI IRSA
 ↘ Flow Log
```

## Version Constraints

- Terraform: >= 1.5.0
- AWS Provider: ~> 6.0
- Kubernetes Provider: ~> 2.38
- Helm Provider: ~> 3.1
- **EKS/Kubernetes**: 1.34 (default, configurable via `kubernetes_version` variable)

## Common Tasks

### Add New Addon
1. Create IRSA role in `src/modules/addons/irsa.tf`
2. Add Helm release in `src/modules/addons/<addon>.tf`
3. Create values file in `src/helm_values/`

### Test Example Deployment
```bash
./scripts/deploy-example.sh   # Deploy hello-world + ALB test
./scripts/cleanup-example.sh  # Cleanup resources
```

## Known Gotchas

- **Helm 3.x syntax**: Use `kubernetes = { ... }` not `kubernetes { ... }` block
- **IAM module v6.x**: Output names are `arn`, `name` (not `iam_role_arn`)
- **First deployment**: `terraform apply -target=module.vpc` then `terraform apply`
- **VPC Flow Log**: v6.x deprecated in root module, use standalone `flow-log` submodule
