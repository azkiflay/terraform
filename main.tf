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
                Name = "Moodle-ASG-Instance"
            }
        }
    }

    resource "aws_autoscaling_group" "moodle_asg" {
        launch_template {
            id      = aws_launch_template.moodle.id
            version = "$Latest"
        }
        min_size             = 0 # Minimum number of instances in the ASG
        max_size             = 0 # Maximum number of instances in the ASG
        desired_capacity     = 0 # Desired number of instances in the ASG
        vpc_zone_identifier  =  data.aws_subnets.default.ids # data.aws_instance.moodle_asg.public_ips # data.aws_subnets.default.ids  # <-- dynamic list of subnet IDs
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

