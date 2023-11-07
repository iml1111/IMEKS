variable "author" {
  type = string
  description = "author"
  default = "IML"
}

variable "region" {
  type = string
  description = "AWS Region"
  default = "us-east-1"
}

variable "dynamodb_table_name" {
  type = string
  description = "AWS Dynamodb Lock Table Name"
  default = "imeks-terraform-lock"
}

variable "s3_log_bucket_name" {
  type = string
  description = "AWS S3 Terraform State Accee Log Bucket Name"
  default = "imeks-terraform-access-logs"
}

variable "s3_log_bucket_target_log_path" {
  type = string
  description = "AWS S3 Terraform State Accee Log Bucket target path"
  default = "log/"
}

variable "s3_state_bucket_name" {
  type = string
  description = "AWS S3 Terraform State Bucket Name"
  default = "imeks-terraform-states"
}