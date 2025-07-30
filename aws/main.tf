provider "aws" {
        region = "us-east-1"
    }
    resource "aws_instance" "moodle_2" {
        ami = "ami-000d841032e72b43c" # --> ubuntu-2004-vm-circleci-classic-1727797387 # UEFI boot required --> "ami-00015f5b5bf56e076" # More ami's https://aws.amazon.com/marketplace
        instance_type = "t2.micro" # More at https://aws.amazon.com/ec2/instance-types/

        tags = {
            Name = "moodle_2"
        }
    }



