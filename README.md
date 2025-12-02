# IMEKS - AWS EKS Terraform Boilerplate

Production-ready AWS EKS infrastructure boilerplate using Terraform. Deploy a complete Kubernetes cluster with a single `terraform apply`.

## Features

- **EKS Cluster**: Kubernetes 1.32 with managed node groups
- **VPC**: Multi-AZ VPC with public/private subnets
- **EKS Addons**: CoreDNS, kube-proxy, vpc-cni, aws-ebs-csi-driver
- **Metrics Server**: Pre-installed for HPA/VPA support
- **ALB Ingress Controller**: AWS Load Balancer Controller with IRSA
- **Security**: IMDSv2 enforcement, EBS encryption, VPC Flow Logs
- **Remote State**: S3 + DynamoDB backend support

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS Region                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                           VPC                              │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                │  │
│  │  │  Public Subnet  │  │  Public Subnet  │                │  │
│  │  │   (AZ-a)        │  │   (AZ-b)        │                │  │
│  │  │   NAT GW        │  │                 │                │  │
│  │  └─────────────────┘  └─────────────────┘                │  │
│  │                                                           │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                │  │
│  │  │ Private Subnet  │  │ Private Subnet  │                │  │
│  │  │   (AZ-a)        │  │   (AZ-b)        │                │  │
│  │  │  ┌───────────┐  │  │  ┌───────────┐  │                │  │
│  │  │  │EKS Node   │  │  │  │EKS Node   │  │                │  │
│  │  │  │(c5.xlarge)│  │  │  │(c5.xlarge)│  │                │  │
│  │  │  └───────────┘  │  │  └───────────┘  │                │  │
│  │  └─────────────────┘  └─────────────────┘                │  │
│  │                                                           │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │                    EKS Cluster                       │ │  │
│  │  │  • Metrics Server                                    │ │  │
│  │  │  • AWS Load Balancer Controller (IRSA)               │ │  │
│  │  │  • CoreDNS, kube-proxy, vpc-cni, ebs-csi-driver      │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- kubectl (optional, for cluster access)

## Quick Start

### 1. Setup Terraform Backend (Optional but Recommended)

```bash
cd assets/terraform_backend
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

### 2. Deploy EKS Infrastructure

```bash
cd src
cp terraform.tfvars.example terraform.tfvars
cp backend.tf.example backend.tf
# Edit terraform.tfvars and backend.tf with your values
terraform init

# First deployment requires two-step apply (EKS module v21.x limitation)
terraform apply -target=module.vpc
terraform apply
```

> **Note**: The two-step deployment is required only for the first `terraform apply`. Subsequent applies work normally. This is due to EKS module v21.x's internal data source dependencies.

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --region ap-northeast-2 --name <cluster-name>
```

## Directory Structure

```
.
├── assets/
│   └── terraform_backend/     # S3 + DynamoDB backend setup
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── README.md
├── src/
│   ├── main.tf                # Main orchestration
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Output values
│   ├── locals.tf              # Local values
│   ├── providers.tf           # Provider configuration
│   ├── versions.tf            # Version constraints
│   ├── backend.tf.example     # Backend configuration template
│   ├── terraform.tfvars.example
│   ├── modules/
│   │   ├── vpc/               # VPC module
│   │   ├── eks/               # EKS module
│   │   └── addons/            # Kubernetes addons (metrics-server, alb-controller)
│   └── helm_values/           # Helm chart values
│       ├── metrics-server.yaml
│       └── aws-load-balancer-controller.yaml
├── examples/
│   └── hello-world/           # Example deployment
├── scripts/                   # Deployment/cleanup scripts
│   ├── deploy-example.sh
│   └── cleanup-example.sh
└── README.md
```

## Configuration

### Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Project name for resource naming | - |
| `environment` | Environment name | `dev` |
| `region` | AWS region | `ap-northeast-2` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `kubernetes_version` | Kubernetes version | `1.32` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `availability_zones_count` | Number of AZs | `2` |
| `single_nat_gateway` | Use single NAT GW | `true` |

> **Note**: Node group settings (instance type, size, etc.) are hardcoded in `src/modules/eks/main.tf` for simplicity. Modify directly if needed.

See `src/variables.tf` for full list of configurable options.

## Module Versions

| Module/Provider | Version |
|-----------------|---------|
| terraform | >= 1.5.0 |
| hashicorp/aws | ~> 6.0 |
| hashicorp/kubernetes | ~> 2.38 |
| hashicorp/helm | ~> 3.1 |
| terraform-aws-modules/vpc/aws | 6.5.1 |
| terraform-aws-modules/eks/aws | 21.10.1 |
| terraform-aws-modules/iam/aws | 6.2.3 |
| metrics-server (Helm) | 3.13.0 |
| aws-load-balancer-controller (Helm) | 1.16.0 |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | EKS API endpoint |
| `configure_kubectl` | Command to configure kubectl |
| `vpc_id` | VPC ID |
| `alb_controller_role_arn` | ALB Controller IAM role ARN |

## Example Deployment

Deploy and test a sample application with ALB Ingress:

```bash
# Deploy and test (includes ALB provisioning wait)
./scripts/deploy-example.sh

# Cleanup
./scripts/cleanup-example.sh
```

Or manually:
```bash
kubectl apply -f examples/hello-world/
```

## Security Features

- **IMDSv2 Required**: Instance metadata service v2 enforced on all nodes
- **EBS Encryption**: Node volumes encrypted at rest
- **VPC Flow Logs**: Network traffic logging enabled
- **IRSA**: IAM roles for service accounts (no static credentials)
- **Private Nodes**: Worker nodes in private subnets only

## Cleanup

```bash
# Remove EKS infrastructure
cd src
terraform destroy

# Remove backend (optional)
cd assets/terraform_backend
terraform destroy
```

## License

MIT License
