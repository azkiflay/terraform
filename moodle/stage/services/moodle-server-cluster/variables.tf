# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "username" {
    description = "The username for the Moodle application"
    type        = string
    default     = "moodleuser"
}
variable "password" {
    description = "The password for the Moodle application"
    type        = string
    default     = "moodlepassword"
}

variable "admin_password" {
    description = "The admin password for the Moodle application"
    type        = string
    default     = "adminpassword"
}



# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket used for the database's remote state storage"
  type        = string
  default = "azkiflay-moodle-tfstate"
}

variable "db_remote_state_key" {
  description = "The name of the key in the S3 bucket used for the database's remote state storage"
  type        = string
  default = "stage/datastores/mysql/terraform.tfstate" # <-- connects to the database remote state
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type        = number
    default     = 80 # If not set, you can do "terraform plan -var "server_port=80" before applying the plan.
}

variable "moodle" {
    description = "Project for a Moodle application"
    type        = string
    default     = "t2.micro" # "moodle"
}


# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------


variable "alb_name" {
  description = "The name of the ALB"
  type        = string
  default     = "moodle-alb"
}

variable "alb_target_group_name" {
  description = "The name of the target group for the ALB"
  type        = string
  default     = "moodle-tg"
  
}

variable "instance_security_group_name" {
  description = "The name of the security group for the EC2 Instances"
  type        = string
  default     = "moodle-instance-sg"
}

variable "alb_security_group_name" {
  description = "The name of the security group for the ALB"
  type        = string
  default     = "moodle-lb-sg"
}

### Packer Configuration
// To make Packer read these variables from the environment into the var object,
// set the environment variables to have the same name as the declared
// variables, with the prefix PKR_VAR_.

/*
// There are other ways to [set variables](/packer/docs/templates/hcl_templates/variables#assigning-values-to-build-variables)
// including from a var file or as a command argument.

// export PKR_VAR_aws_access_key=$YOURKEY
variable "aws_access_key" {
  type = string
  // default = "hardcoded_key"
}

// export PKR_VAR_aws_secret_key=$YOURSECRETKEY
variable "aws_secret_key" {
  type = string
  // default = "hardcoded_secret_key"
}
*/

