terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "azkiflay-moodle-terraform-state" # Must be globally unique
    key            = "backend/s3/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true  # S3 native locking # dynamodb_table is deprecated from Terraform version 1.11.0 or higher.
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = "azkiflay-moodle-terraform-state" # Must be globally unique
  // This is only here so we can destroy the bucket as part of automated tests. You should not copy this for production
  // usage
  force_destroy = true # Prevent accidental deletion of an important resource, such as this S3 bucket
}

# Enable versioning so you can see the full revision history of your state files
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

output "alb_dns_name" {
    value       = aws_lb.moodle.dns_name
    description = "The domain name of the load balancer"
}

output "s3_bucket_domain_name" {
  value       = aws_s3_bucket.terraform_state.bucket_domain_name
  description = "The domain name of the S3 bucket"
}


/*
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "azkiflay-moodle-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  lifecycle {
    prevent_destroy = false
  }
}
*/