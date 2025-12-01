# =============================================================================
# DynamoDB Table for Terraform State Locking
# =============================================================================
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = local.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = local.dynamodb_table_name
    Purpose = "Terraform State Locking"
  }
}

# =============================================================================
# S3 Bucket for Access Logs
# =============================================================================
resource "aws_s3_bucket" "terraform_logs" {
  bucket = local.s3_log_bucket_name

  tags = {
    Name    = local.s3_log_bucket_name
    Purpose = "Terraform State Access Logs"
  }
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

# Public Access Block for Logs Bucket
resource "aws_s3_bucket_public_access_block" "terraform_logs_public_access_block" {
  bucket = aws_s3_bucket.terraform_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-Side Encryption for Logs Bucket (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_logs_encryption" {
  bucket = aws_s3_bucket.terraform_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# =============================================================================
# S3 Bucket for Terraform State
# =============================================================================
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.s3_state_bucket_name

  tags = {
    Name    = local.s3_state_bucket_name
    Purpose = "Terraform State Storage"
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

# Versioning for State Bucket
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Public Access Block for State Bucket
resource "aws_s3_bucket_public_access_block" "terraform_state_public_access_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-Side Encryption for State Bucket (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Bucket Policy - Enforce HTTPS Only
resource "aws_s3_bucket_policy" "terraform_state_policy" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.terraform_state_public_access_block
  ]
}

# Logging for State Bucket
resource "aws_s3_bucket_logging" "terraform_state_logging" {
  bucket        = aws_s3_bucket.terraform_state.id
  target_bucket = aws_s3_bucket.terraform_logs.id
  target_prefix = var.s3_log_bucket_target_log_path
}
