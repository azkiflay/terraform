data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}


data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-1"
  }
}

/*

# Output all private IPs
output "asg_private_ips" {
  value = [for i in data.aws_autoscaling_group.moodle : i.private_ip]
}

# Output all public IPs
output "asg_public_ips" {
  value = [for i in data.aws_autoscaling_group.moodle : i.public_ip]
}

*/




