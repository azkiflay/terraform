terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type        = number
    default     = 80 # If not set, you can do "terraform plan -var "server_port=80" before applying the plan.
}

variable "moodle" {
    description = "Project for a Moodle application"
    type        = string
    default     = "t2.micro"
}

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


resource "aws_security_group" "moodle_instance_sg" {
    name = "${var.moodle}-instance-sg"
    description = "Allow TCP traffic on port ${var.server_port}"
    vpc_id      = data.aws_vpc.default.id
    ingress { 
        from_port = var.server_port
        protocol = "tcp"
        to_port = var.server_port 
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow inbound HTTP on port ${var.server_port}"
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }
}

resource "aws_launch_template" "moodle" {
    image_id = data.aws_ami.ubuntu.id # image_id      = "ami-000d841032e72b43c" # when not cluster --> ami = "ami-000d841032e72b43c" as above
    instance_type = "t2.micro"
    name_prefix   = "${var.moodle}-lt-"
    vpc_security_group_ids = [aws_security_group.moodle_instance_sg.id]

    # user_data # Base64 encoded user data script required for the launch template
    user_data = base64encode(<<-EOF
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p ${var.server_port} &
EOF
)

    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "moodle"
        }
    }
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "moodle" {
    min_size             = 3
    max_size             = 10
    # desired_capacity     = 5
    vpc_zone_identifier  =  data.aws_subnets.default.ids
    # availability_zones = data.aws_availability_zones.available.names
    target_group_arns = [aws_lb_target_group.moodle.arn]  # Which EC2 instance to send requests to
    health_check_type = "ELB"  
    health_check_grace_period = 300  
    launch_template {
        id      = aws_launch_template.moodle.id
        version = aws_launch_template.moodle.latest_version # version = "$Latest"
    }
    tag {
        key                 = "Name"
        value               = "${var.moodle}-asg"
        propagate_at_launch = true
  }
}

# Load Balancer Configuration
resource "aws_lb" "moodle" {
    name = "moodle-lb"
    load_balancer_type = "application"
    internal           = false                     # This makes it public-facing
    subnets = data.aws_subnets.default.ids # data.aws_subnets.public.ids # Load balancer uses all public subnets
    security_groups = [aws_security_group.moodle_lb_sg.id] # Security group for the load balancer
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.moodle.arn
    port = var.server_port
    protocol = "HTTP"
    /*
    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.moodle.arn
    }
    */

    # By default, return simple 404 page
    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found."
            status_code = 404
        }
    }
}


resource "aws_lb_target_group" "moodle" {
    name = "moodle-lb-tg"
    port     = var.server_port
    protocol = "HTTP"
    vpc_id   = data.aws_vpc.default.id
    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher =           "200"
        interval            = 15
        timeout             = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2

    }
}

resource "aws_lb_listener_rule" "moodle" {
    listener_arn = aws_lb_listener.http.arn
    priority      = 100
    action {
        type = "forward"
        forward {
            target_group {
                arn = aws_lb_target_group.moodle.arn
            }
        }
    }
    condition {
        path_pattern {
            values = ["*"]
        }
    }
    
}

resource "aws_security_group" "moodle_lb_sg" {
    name        = "moodle"
    # vpc_id      = data.aws_vpc.default.id
    description = "Security group for the Moodle load balancer"
    # "Allow inbound HTTP requests"
    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # Allow all outbound requests
    egress {
        from_port   = 0 # Allow all inbound traffic
        to_port     = 0 # Allow all outbound traffic
        protocol    = "-1" # -1 means all protocols
        cidr_blocks = ["0.0.0.0/0"] # Allow traffic to all possible IP addresses
    }
}

output "alb_dns_name" {
    value       = aws_lb.moodle.dns_name
    description = "The domain name of the load balancer"
}