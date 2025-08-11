output "s3_bucket_domain_name" {
  value       = aws_s3_bucket.terraform_state.bucket_domain_name
  description = "The domain name of the S3 bucket"
}