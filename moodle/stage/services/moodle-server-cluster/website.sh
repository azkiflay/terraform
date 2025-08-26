#!/bin/sh -x
set -e
# Force non-interactive frontend for all apt commands
echo 'export DEBIAN_FRONTEND=noninteractive' | sudo tee -a /etc/environment

# Install nginx
sudo apt-get -y install nginx
sudo mkdir -p /var/www/website
sudo sh -c "echo '<html><h1>This is a website</h1></html>' > /var/www/website/index.html"