provider "aws" {
        region = "us-east-1"
    }
    resource "aws_instance" "moodle" {
        ami = "ami-000d841032e72b43c" # --> ubuntu-2004-vm-circleci-classic-1727797387 # UEFI boot required --> "ami-00015f5b5bf56e076" # More ami's https://aws.amazon.com/marketplace
        instance_type = "t2.micro" # More at https://aws.amazon.com/ec2/instance-types/
        vpc_security_group_ids = [aws_security_group.moodle_sg.id]
        tags = {
            Name = "moodle"
        }

        user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html 
            nohup busybox httpd -f -p 8080 & 
            EOF

        user_data_replace_on_change = true # --> forcefully terminate the original instance and create a new one to ensure user data script is executed.
    }
    resource "aws_security_group" "moodle_sg" { 
        name = "moodle_sg_allow_tcp_8080"
        description = "Allow TCP traffic on port 8080"
        ingress { 
            from_port = 8080
            protocol = "tcp"
            to_port = 8080
            cidr_blocks = ["0.0.0.0/0"] # Allow traffic from all possible IP addresses
            }
    }
