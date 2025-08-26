variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
  default     = "azkiflay-moodle-tfstate" # Change this to a unique name for your S3 bucket
}

variable "table_name" {
  description = "The name of the DynamoDB table. Must be unique in this AWS account."
  type        = string
  default     = "azkiflay-moodle-terraform-lock"
}