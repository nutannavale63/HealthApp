# Main Terraform configuration for BBHealthApp EKS deployment

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# CloudWatch Log Group for EKS
# Note: The EKS module already creates this log group, so this resource is disabled
# resource "aws_cloudwatch_log_group" "eks_logs" {
#   count = var.enable_cloudwatch_logging ? 1 : 0
#
#   name              = "/aws/eks/${var.cluster_name}/cluster"
#   retention_in_days = 7
#
#   lifecycle {
#     create_before_destroy = true
#   }
#
#   tags = merge(
#     local.common_tags,
#     var.tags,
#     {
#       Name = "${var.project_name}-eks-logs"
#     }
#   )
# }

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state-${local.account_id}-${local.region}"

  tags = merge(
    local.common_tags,
    var.tags,
    {
      Name = "${var.project_name}-terraform-state-${local.account_id}-${local.region}"
    }
  )
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for Terraform state locking
# Note: Table already created manually during setup
# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "${var.project_name}-terraform-locks-${local.account_id}-${local.region}"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
#
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
#
#   tags = merge(
#     local.common_tags,
#     var.tags,
#     {
#       Name = "${var.project_name}-terraform-locks-${local.account_id}-${local.region}"
#     }
#   )
# }
