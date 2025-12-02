# =============================================================================
# Terraform Backend Configuration
# =============================================================================
# Copy this file to backend.tf and update with your backend values:
#   cp backend.tf.example backend.tf
#
# Get the values from: cd ../assets/terraform_backend && terraform output
# =============================================================================

terraform {
  backend "s3" {
    bucket         = "alocados-terraform-states"
    key            = "imeks.terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "alocados-terraform-lock"
    encrypt        = true
  }
}
