#!/bin/bash
set -e
# Force non-interactive frontend for all apt commands
echo 'export DEBIAN_FRONTEND=noninteractive' | sudo tee -a /etc/environment


## Install the LAMP stack as the webserver
PROTOCOL="http://";
export DBNAME="moodle"
export DBUSER="moodle_user"
export DBPASS="moodle_pass"
export MOODLE_ADMIN_PASSWORD="MyAdminPassword@897"

echo "DBNAME is $DBNAME"
echo "DBUSER is $DBUSER"
echo "DBPASS is $DBPASS"
echo "MOODLE_ADMIN_PASSWORD is $MOODLE_ADMIN_PASSWORD"
echo "PROTOCOL is $PROTOCOL"