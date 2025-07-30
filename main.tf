provider "aws" {
        region = "us-east-1"
    }
    
    resource "aws_instance" "moodle" {
        ami = "ami-000d841032e72b43c" # --> ubuntu-2004-vm-circleci-classic-1727797387 # UEFI boot required --> "ami-00015f5b5bf56e076" # More ami's https://aws.amazon.com/marketplace
        instance_type = "t2.micro" # More at https://aws.amazon.com/ec2/instance-types/
        vpc_security_group_ids = [aws_security_group.moodle_security_group.id]
        tags = {
            Name = "moodle"
        }

        user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p ${var.server_port} & # 8080
            echo "Web server started on port ${var.server_port}"
            echo "You can access the web server at http://\$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):${var.server_port}/"
            echo "You can also access the web server at http://\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):${var.server_port}/"
            EOF

        user_data_replace_on_change = true # --> forcefully terminate the original instance and create a new one to ensure user data script is executed.
    }
    resource "aws_security_group" "moodle_security_group" { 
        name = "moodle_security_group_allow_tcp_8080"
        description = "Allow TCP traffic on port 8080"
        ingress { 
            from_port = var.server_port # 8080
            protocol = "tcp"
            to_port = var.server_port # 8080
            cidr_blocks = ["0.0.0.0/0"] # Allow traffic from all possible IP addresses
            }
    }
    variable "object_example_with_error" {
        description = "An example of a structural type in Terraform"
        type = object({
            tags = list(string)
            age  = number
            name = string
            enabled = bool
            })
        default = { 
            name = "value1"
            tags = ["a", "b", "c"]
            age  = 2
            name = "value1"
            enabled = true
        }
    }

    variable "server_port" {
        description = "The port the server will use for HTTP requests"
        type        = number
        # default     = 8080 # If not set, you can do "terraform plan -var "server_port=8080" before applying the plan.
    }

    output "public_ip" {
        value       = aws_instance.moodle.public_ip # This will output the public IP address of the web server
        sensitive   = false # Set to true if you want to hide the output in the console
        description = "The public IP address of the web server"
    }

    
    resource "aws_launch_template" "web" {
        name_prefix   = "web-"
        image_id      = "ami-000d841032e72b43c" # when not cluster --> ami = "ami-000d841032e72b43c" as above
        instance_type = "t2.micro"
    
        lifecycle {
            create_before_destroy = true
        }
        # user_data # Base64 encoded user data script required for the launch template
    }

    resource "aws_autoscaling_group" "web_asg" {
        launch_template {
            id      = aws_launch_template.web.id
            version = "$Latest"
        }
        min_size             = 2 # Minimum number of instances in the ASG
        max_size             = 10 # Maximum number of instances in the ASG
        desired_capacity     = 5 # Desired number of instances in the ASG
        vpc_zone_identifier  = data.aws_subnets.default.ids  # <-- dynamic list of subnet IDs # vpc_zone_identifier = ["subnet-12345678"] # Replace with your subnet ID
        health_check_type   = "EC2" # Health check type for the ASG
        health_check_grace_period = 300 # Time in seconds to wait before checking the health
        force_delete         = true # Force delete the ASG when destroying the resource
        wait_for_capacity_timeout = "0" # Wait for capacity to be available before proceeding
    }

   # Get the default VPC
    data "aws_vpc" "default" {
        default = true
    }

    # Get all subnets in that VPC
    data "aws_subnets" "default" {
        filter {
            name   = "vpc-id"
            values = [data.aws_vpc.default.id]
        }
    }

    output "subnet_ids" {
    value = data.aws_subnets.default.ids
    }
