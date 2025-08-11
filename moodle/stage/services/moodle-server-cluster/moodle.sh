#!/bin/bash
## Install the LAMP stack as the webserver
PROTOCOL="http://";
# Note: Enter "moodle.local" or publicly registered website name for your Moodle site.
# read -p "Enter the web address (without the http:// prefix, eg domain name mymoodle123.com or IP address 192.168.1.1.): " WEBSITE_ADDRESS # Note: Enter "moodle.local" or publicly registered website name for your Moodle site.
# sudo nano /etc/hosts
## Get Moodle code using Git
sudo apt-get update && sudo apt upgrade -y 
sudo apt-get -y install apache2 php libapache2-mod-php php-mysql graphviz aspell git clamav php-pspell php-curl php-gd php-intl ghostscript php-xml php-xmlrpc php-ldap php-zip php-soap php-mbstring unzip mariadb-server mariadb-client certbot python3-certbot-apache ufw nano
cd /var/www/html # Note: may require root privilege?
sudo git clone https://github.com/moodle/moodle.git 
cd moodle 
sudo git checkout origin/MOODLE_500_STABLE 
sudo git config pull.ff only
## Configure specific Moodle requirements
sudo mkdir -p /var/www/moodledata
sudo chown -R www-data:www-data /var/www/moodledata
sudo find /var/www/moodledata -type d -exec chmod 700 {} \; 
sudo find /var/www/moodledata -type f -exec chmod 600 {} \;
PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") 
sudo sed -i 's/.*max_input_vars =.*/max_input_vars = 5000/' /etc/php/$PHP_VERSION/apache2/php.ini 
sudo sed -i 's/.*max_input_vars =.*/max_input_vars = 5000/' /etc/php/$PHP_VERSION/cli/php.ini 
sudo sed -i 's/.*post_max_size =.*/post_max_size = 256M/' /etc/php/$PHP_VERSION/apache2/php.ini 
sudo sed -i 's/.*post_max_size =.*/post_max_size = 256M/' /etc/php/$PHP_VERSION/cli/php.ini 
sudo sed -i 's/.*upload_max_filesize =.*/upload_max_filesize = 256M/' /etc/php/$PHP_VERSION/apache2/php.ini 
sudo sed -i 's/.*upload_max_filesize =.*/upload_max_filesize = 256M/' /etc/php/$PHP_VERSION/cli/php.ini 
sudo echo "* * * * * /usr/bin/php /var/www/html/moodle/admin/cli/cron.php >/dev/null" | sudo crontab -u www-data - # Error: "must be privileged to use -u", if last 'sudo' is not present as in the official Moodle instllation web page.
## Database and user creation
# MYSQL_MOODLEUSER_PASSWORD=$(openssl rand -base64 6)
sudo mysql -e "CREATE DATABASE moodle DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER '${username}'@'localhost' IDENTIFIED BY '${password}';"
sudo mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER ON moodle.* TO '${username}'@'localhost';"
# echo "Your Moodle user password is ${password}. Write this down as you will need it in a web browser install"
# Your Moodle user password is 3gqxSWin. Write this down as you will need it in a web browser install
## Moodle configuration on the Web Server
sudo chown -R www-data:www-data /var/www/html/moodle
# MOODLE_ADMIN_PASSWORD=$(openssl rand -base64 6)
sudo -u www-data /usr/bin/php /var/www/html/moodle/admin/cli/install.php --non-interactive --lang=en --wwwroot="$PROTOCOL${website_url}/moodle" --dataroot=/var/www/moodledata --dbtype=mariadb --dbhost=localhost --dbname=moodle --dbuser=moodleuser2 --dbpass="${password}" --fullname="Moodle Docs Step by Step Guide" --shortname="SG" --adminuser=admin --summary="" --adminpass="${admin_password}" --adminemail=joe@123.com --agree-license
# Installation completed successfully.
# Note: moodleuser2 due to repeated command runs. Otherwise, Error: "PHP Warning:  mysqli::__construct(): (HY000/1045): Access denied for user 'moodleuser'@'localhost' (using password: YES) in /var/www/html/moodle/lib/dml/mysqli_native_moodle_database.php on line 91 --> "We could not connect to the database you specified. Please check your database settings."
# Error: Could not open input file: /var/www/html/moodle/admin/cli/install.php
echo "Moodle installation completed successfully. You can now log on to your new Moodle at $PROTOCOL${website_url}/moodle as admin with ${admin_password} and complete your site registration"
# Moodle installation completed successfully. You can now log on to your new Moodle at http://moodle.local/moodle as admin with "+j0T+YVK" and complete your site registration
reboot