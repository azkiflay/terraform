terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  
  backend "s3" {
    bucket         = "azkiflay-moodle-tfstate" # Must be globally unique
    key            = "stage/datastores/mysql/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true  # S3 native locking # dynamodb_table is deprecated from Terraform version 1.11.0 or higher.
    encrypt        = true
  }
  
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "db" {
  identifier_prefix   = "azkiflay-moodle-tfstate"
  engine              = "mysql"
  # engine_version       = "8.0.42"
  allocated_storage   = 10
  instance_class       = "db.t3.micro" # "db.t2.micro" --> RDS not supported in free tier
  skip_final_snapshot = true
  db_name             = var.db_name
  username = var.db_username
  password = var.db_password
}
