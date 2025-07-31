provider "aws" {
        region = "us-east-1"
    }
    
resource "aws_security_group" "moodle_sg" { 
    name = "allow_tcp_8080"
    description = "Allow TCP traffic on port 8080"
    ingress { 
        from_port = var.server_port # 8080
        protocol = "tcp"
        to_port = var.server_port # 8080
        cidr_blocks = ["0.0.0.0/0"] # Allow traffic from all possible IP addresses
        }
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type        = number
    default     = 8080 # If not set, you can do "terraform plan -var "server_port=8080" before applying the plan.
}

data "aws_vpc" "default" { # Get the default VPC
    default = true
}

data "aws_subnets" "default" { # Get all subnets in that VPC
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

data "aws_subnets" "public" {
    filter {
        name   = "tag:Type"
        values = ["public"]
    }
}



output "subnet_ids" {
    value = data.aws_subnets.default.ids
}


resource "aws_launch_template" "moodle" {
    image_id      = "ami-000d841032e72b43c" # when not cluster --> ami = "ami-000d841032e72b43c" as above
    instance_type = "t2.micro"

    lifecycle {
        create_before_destroy = true
    }
    # user_data # Base64 encoded user data script required for the launch template
    user_data = base64encode(<<-EOF
        #!/bin/bash
        echo "Hello, World" > index.html 
        nohup busybox httpd -f -p 8080 & 
        EOF
    )
    tag_specifications {
            resource_type = "instance"
            tags = {
            Name = "moodle-asg-instance"
        }
    }
}

resource "aws_autoscaling_group" "moodle_asg" {
    launch_template {
        id      = aws_launch_template.moodle.id
        version = "$Latest"
    }
    min_size             = 3 # Minimum number of instances in the ASG
    max_size             = 10 # Maximum number of instances in the ASG
    desired_capacity     = 5 # Desired number of instances in the ASG
    vpc_zone_identifier  =  data.aws_subnets.default.ids # data.aws_instance.moodle_asg.public_ips # data.aws_subnets.default.ids  # <-- dynamic list of subnet IDs
    
    target_group_arns = [aws_lb_target_group.asg.arn] 
    health_check_type = "ELB" # health_check_type    = "EC2" # "EC2" --> only minimum health check (i.e. up or down?)
}

# Load Balancer Configuration
# Create an Application Load Balancer (ALB) for the ASG instances
resource "aws_lb" "moodle" {
    name = "moodle-alb"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids # Load balancer uses all subnets
    security_groups = [aws_security_group.alb.id] # Security group for the load balancer
}

# Listener for the Load Balancer
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.moodle.arn
    port = 80
    protocol = "HTTP"
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

# Target Group for the ASG
resource "aws_lb_target_group" "asg" {
    name     = "moodle-target-group"
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

# Security Group for the Load Balancer
resource "aws_security_group" "alb" {
    name        = "moodle-alb-sg"
    # "Allow inbound HTTP requests"
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # Allow all outbound requests
    egress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority      = 100
    condition {
        path_pattern {
            values = ["*"]
        }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg.arn
    }
}

output "alb_dns_name" {
    value       = aws_lb.moodle.dns_name
    description = "The domain name of the load balancer"
}