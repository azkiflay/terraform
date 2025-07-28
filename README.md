# Introduction

# Terraform Configuration Management
Terraform is an IaC. Terraform can work with dedicated configuration management (CM) to automate infrastructure configuration.
## On lauch setup using shell scripts
On launch, Terraform can be configured to create and instantiate infrastructed by running a shell script.

```bash
    provider "aws" {
        region = "us-east-1"
    }
    resource "aws_instance" "moodle" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"

    user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html 
    nohup busybox httpd -f -p 8080 & 
    EOF

    tags = { 
        Name = "moodle-instance"
        } 
    }
```

The shell script that is specified within the "*user_data*" parameter runs at launch of the instance. Similarly, software can be installed, services configured and started. Shorter scripts can be inserted using "*<<- EOF ... EOF*" as shown above. However, for long shell scripts, it is better to save them as separate files and load them to Terraform using the **file()** function.


## Ansible with Terraform

```bash
    provider "aws" {
        region = "us-east-1"
    }
    resource "aws_instance" "moodle" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"

    user_data = <<-EOF
    #!/bin/bash apt-get update
    apt-get install -y ansible
    echo "${file("ansible.cfg")}" > /etc/ansible/ansible.cfg
    echo "${file("hosts")}" > /etc/ansible/hosts
    EOF

    tags = { 
        Name = "moodle-instance"
        } 
    }
```
With the **ansible.cfg** and **hosts** created at the same directory as the Terrform configuration file, the function **file()** is used copy the files to the instance launched by Terraform.

Note that script passed through the *user_data* parameter is run only once during the launch of the instance. To make further changes can be made using SSH-based remote access or preferrably Ansible playbooks. Instead of storing your Ansible configuration files locally, it is a good practice to store them in a securre repository. In this way, while Terraform creates the infrastructure, Ansible automates the configuration.