terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  
  backend "s3" {
    bucket         = "azkiflay-moodle-tfstate" # Must be globally unique
    key            = "stage/services/moodle-server-cluster/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true  # S3 native locking # dynamodb_table is deprecated from Terraform version 1.11.0 or higher.
    encrypt        = true
  }
  
}

provider "aws" {
    region = "us-east-1"
}


resource "aws_security_group" "moodle_instance_sg" {
    name = "${var.moodle}-instance-sg" # name        = var.instance_security_group_name # name = "${var.moodle}-instance-sg"
    description = "Allow TCP traffic on port ${var.server_port}"
    vpc_id      = local.vpc_id # data.aws_vpc.default.id

    # Allow inbound SSH traffic
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow inbound HTTP traffic
    ingress {
        from_port = var.server_port
        protocol = "tcp"
        to_port = var.server_port 
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow inbound HTTP on port ${var.server_port}"
    }
    # Allow all outbound traffic
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }
}

# Read AMI ID from Packer's manifest
locals {
  packer_manifest = jsondecode(file("${path.module}/manifest.pkr.json"))

  # Extract artifact_id and strip the "region:" prefix
  ami_id = replace(local.packer_manifest.builds[0].artifact_id, "us-east-1:", "")

  vpc_id           = data.aws_vpc.default.id
  subnet_id        = data.aws_subnets.default.ids[0] # Use the first subnet in the list
  ssh_user         = "ubuntu"
  key_name         = "key_pair_moodle"
  private_key_path = "~/.ssh/key_pair_moodle.pem"
}

resource "aws_launch_template" "moodle" {
    image_id = local.ami_id # data.aws_ami.ubuntu.id # when not cluster --> ami = "ami-000d841032e72b43c" as above
    instance_type = "t2.micro"
    name_prefix   = "${var.moodle}-lt-"
    vpc_security_group_ids = [aws_security_group.moodle_instance_sg.id]

    key_name      = local.key_name

    /*
    # Base64 encoded user data script required for the launch template
    user_data = base64encode(templatefile("${path.module}/userdata.tpl", {
        repo_url = "https://github.com/azkiflay/ansible-for-terraform.git"
        playbook = "moodle.yml"
    }))
    */
    
    /*
    # Render the User Data script as a template
    user_data = base64encode(templatefile("moodle.sh", {
        server_port = var.server_port
        db_address  = data.terraform_remote_state.db.outputs.address
        db_port     = data.terraform_remote_state.db.outputs.port
        username = var.username 
        password = var.password
        admin_password = var.admin_password
        website_url  = aws_lb.moodle.dns_name # <-- Use the ALB DNS name as the website URL
    }))
    */
    

    user_data = base64encode(<<-EOF
#!/bin/bash
echo "Hello, World" > index.html
nohup busybox httpd -f -p ${var.server_port} &
EOF
)

    tags = {
        Name = "Ubuntu-Packer-Instance"
    }
   
    tag_specifications {
        resource_type = "instance"
        tags = {
            Name = "${var.moodle}"
        }
    }
    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "moodle" {
    min_size             = 2
    max_size             = 5
    vpc_zone_identifier  = data.aws_subnets.default.ids
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
    name = "moodle-alb" # name               = var.alb_name # name = "moodle-lb"
    load_balancer_type = "application"
    internal           = false
    subnets            = data.aws_subnets.default.ids
    security_groups    = [aws_security_group.moodle_lb_sg.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.moodle.arn
    port              = var.server_port
    protocol          = "HTTP"
    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found."
            status_code = 404
        }
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

resource "aws_lb_target_group" "moodle" {
    name = "moodle-lb-tg" # name     = var.alb_target_group_name
    port     = var.server_port
    protocol = "HTTP"
    vpc_id   = local.vpc_id # data.aws_vpc.default.id
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

resource "aws_security_group" "moodle_lb_sg" {
    name        = "moodle" # name        = var.alb_security_group_name
    description = "Security group for the Moodle load balancer"
    
    # "Allow inbound SSH requests"
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

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

resource "null_resource" "run_ansible" {
    depends_on = [aws_lb.moodle]
    /*
    provisioner "remote-exec" {
        inline = ["echo 'Wait until SSH is ready'"]

        connection {
        type        = "ssh"
        user        = local.ssh_user
        private_key = file(local.private_key_path)
        host        = aws_lb.moodle.dns_name
        }
    }
    */
    provisioner "local-exec" {
            command = "ansible-playbook -u ansible -i ${aws_lb.moodle.dns_name}, --private-key ${local.private_key_path} ./ansible/playbook_terraform.yml" # -e alb_dns_name=$(terraform output -raw alb_dns_name)"
        }
  }



/*
# Ansible Provisioning
# Example to run Ansible locally on those instances:
resource "null_resource" "run_ansible" {
  depends_on = [aws_autoscaling_group.asg]

  provisioner "local-exec" {
    command = <<EOT
      ansible-playbook -i '${join(",", [for inst in data.aws_instance.moodle_instances : inst.private_ip])}' playbook_terraform.yml
    EOT
  }
}
*/



/*
provisioner "remote-exec" {
        connection {
        type        = "ssh"
        user        = "ubuntu" # or ec2-user, depending on AMI
        private_key = file("~/.ssh/key_pair_moodle.pem")
        host        = data.aws_instances.asg_instances.private_ips[*]
        timeout     = "5m"
        }
        inline = ["echo SSH ready on instance."]
    }
    
    provisioner "file" {
        source      = "moodle.sh"
        destination = "/home/ubuntu/moodle.sh"
    }

    provisioner "remote-exec" {
        inline = [
            "chmod +x /home/ubuntu/moodle.sh",
            "sudo /home/ubuntu/moodle.sh"
        ]
    }

*/
