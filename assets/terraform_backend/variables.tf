# =============================================================================
# Terraform Backend Variables
# =============================================================================

variable "region" {
  type        = string
  description = "AWS Region for backend resources"
  default     = "ap-northeast-2"
}

variable "project_name" {
  type        = string
  description = "Project name used as prefix for resource names"
  default     = "imeks"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, 2-21 characters, starting with a letter."
  }
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name for the DynamoDB state lock table (leave empty to auto-generate from project_name)"
  default     = ""
}

variable "s3_state_bucket_name" {
  type        = string
  description = "Name for the S3 state bucket (leave empty to auto-generate from project_name)"
  default     = ""
}

variable "s3_log_bucket_name" {
  type        = string
  description = "Name for the S3 access logs bucket (leave empty to auto-generate from project_name)"
  default     = ""
}

variable "s3_log_bucket_target_log_path" {
  type        = string
  description = "Target path prefix for access logs"
  default     = "log/"
}

# =============================================================================
# Local Values for Name Generation
# =============================================================================
locals {
  dynamodb_table_name  = var.dynamodb_table_name != "" ? var.dynamodb_table_name : "${var.project_name}-terraform-lock"
  s3_state_bucket_name = var.s3_state_bucket_name != "" ? var.s3_state_bucket_name : "${var.project_name}-terraform-states-${data.aws_caller_identity.current.account_id}"
  s3_log_bucket_name   = var.s3_log_bucket_name != "" ? var.s3_log_bucket_name : "${var.project_name}-terraform-logs-${data.aws_caller_identity.current.account_id}"
}