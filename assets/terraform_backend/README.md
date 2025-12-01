# Terraform Backend Infrastructure

This directory contains Terraform configuration for setting up the remote backend infrastructure (S3 + DynamoDB) for Terraform state management.

## Why Remote Backend?

- **State Locking**: DynamoDB prevents concurrent modifications
- **Versioning**: S3 versioning enables state recovery
- **Security**: AES-256 encryption, HTTPS enforcement, public access blocking
- **Collaboration**: Shared state for team environments

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0

## Quick Start

```bash
# 1. Navigate to backend directory
cd assets/terraform_backend

# 2. Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# 3. Initialize Terraform
terraform init

# 4. Review the plan
terraform plan

# 5. Apply the configuration
terraform apply

# 6. Note the outputs for main infrastructure setup
```

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | AWS region | `ap-northeast-2` |
| `project_name` | Project prefix for resource names | `imeks` |
| `dynamodb_table_name` | Custom DynamoDB table name | Auto-generated |
| `s3_state_bucket_name` | Custom S3 state bucket name | Auto-generated |
| `s3_log_bucket_name` | Custom S3 logs bucket name | Auto-generated |

## Created Resources

- **DynamoDB Table**: `{project_name}-terraform-lock`
  - PAY_PER_REQUEST billing
  - Used for state locking

- **S3 State Bucket**: `{project_name}-terraform-states-{account_id}`
  - AES-256 server-side encryption
  - Versioning enabled
  - Public access blocked
  - HTTPS-only policy

- **S3 Logs Bucket**: `{project_name}-terraform-logs-{account_id}`
  - AES-256 server-side encryption
  - Public access blocked
  - Stores access logs for state bucket

## Outputs

After applying, you'll receive:

- `terraform_state_bucket_name` - S3 bucket name for backend configuration
- `terraform_state_lock_table_name` - DynamoDB table name for backend configuration
- `backend_config` - Ready-to-use backend configuration block

## Using with Main Infrastructure

After deploying the backend, copy the output `backend_config` to create `src/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "<output-bucket-name>"
    key            = "eks/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "<output-table-name>"
    encrypt        = true
  }
}
```

Then initialize the main infrastructure:

```bash
cd ../../src
terraform init
```

## Security Features

- **AES-256 Encryption**: All data encrypted at rest
- **Public Access Block**: All 4 settings enabled
- **HTTPS Enforcement**: Bucket policy denies insecure transport
- **Versioning**: State recovery from previous versions
- **Access Logging**: Audit trail for state bucket access

## Cleanup

To destroy the backend infrastructure:

```bash
# WARNING: This will delete all state files!
# Make sure to backup state first if needed

terraform destroy
```

> **Note**: You must first remove any state files and disable versioning, or empty the buckets manually before destruction.
