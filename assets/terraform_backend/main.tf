resource "aws_dynamodb_table" "terraform_state_lock" {
  name = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "terraform_logs" {
  bucket = var.s3_log_bucket_name
}
resource "aws_s3_bucket_ownership_controls" "terraform_logs_ownership_controls" {
  bucket = aws_s3_bucket.terraform_logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "terraform_logs_acl" {
  bucket = aws_s3_bucket.terraform_logs.id
  
  access_control_policy {
    grant {
      grantee {
        type = "CanonicalUser"
        id   = data.aws_canonical_user_id.current.id
      }
      permission = "FULL_CONTROL"
    }
    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "WRITE"
    }
    grant {
      grantee {
        type = "Group"
        uri  = "http://acs.amazonaws.com/groups/s3/LogDelivery"
      }
      permission = "READ_ACP"
    }
    
    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }

  depends_on = [
    aws_s3_bucket_ownership_controls.terraform_logs_ownership_controls
  ]
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.s3_state_bucket_name
  tags = {
    Name = "terraform_state"
  }
}
resource "aws_s3_bucket_ownership_controls" "terraform_state_ownership_controls" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_acl" "terraform_state_acl" {
  bucket = aws_s3_bucket.terraform_state.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.terraform_state_ownership_controls
  ]
}
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "terraform_state_logging" {
  bucket = aws_s3_bucket.terraform_state.id
  target_bucket = aws_s3_bucket.terraform_logs.id
  target_prefix = var.s3_log_bucket_target_log_path
}