// To make Packer read these variables from the environment into the var object,
// set the environment variables to have the same name as the declared
// variables, with the prefix PKR_VAR_.

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

source "amazon-ebs" "ubuntu-moodle" {
  access_key = var.aws_access_key
  secret_key =  var.aws_secret_key
  region =  "us-east-1"
  source_ami = "ami-fce3c696" # TODO: update/verify source_ami # "ami-04aabc615a35e0941" # <-- from AWS Public AMI for Ubuntu 22.04 - CIS L2 - ShadowSocks 0.1.5 - Sanitized Release Candidate-920ba0b7-704b-47b4-8ac6-5f5d83e96b06
  instance_type =  "t2.micro"
  ssh_username =  "ubuntu"
  ami_name =  "packer_AWS {{timestamp}}"
}

build {
  sources = [
    "source.amazon-ebs.ubuntu-moodle"
  ]
  provisioner "ansible" {
    playbook_file = "playbook_packer.yml"
  }
  provisioner "shell" {
        inline = [
            "sudo adduser --disabled-password --gecos '' ansible",
            "sudo usermod -aG sudo ansible",
            "echo 'ansible ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/90-ansible-nopasswd",
            "sudo chmod 440 /etc/sudoers.d/90-ansible-nopasswd"
        ]
    }

  post-processor "manifest" {
    output     = "manifest.pkr.json"
    strip_path = true
  }
  
  
}
