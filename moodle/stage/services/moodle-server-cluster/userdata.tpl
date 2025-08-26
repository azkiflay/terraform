#!/bin/bash
# Install Ansible and Git
apt-get update -y
apt-get install -y git ansible
echo "Hello World from EC2 Load Balancer!"
# Run Ansible pull
ansible-pull -U ${repo_url} ${playbook}
