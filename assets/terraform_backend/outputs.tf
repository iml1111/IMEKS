output "terraform_state_bucket" {
  value = var.s3_state_bucket_name
}

output "terraform_state_lock" {
  value = var.dynamodb_table_name
}