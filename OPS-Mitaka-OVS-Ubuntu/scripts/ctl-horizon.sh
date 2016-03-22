#!/bin/bash -ex

source config.cfg
source functions.sh

echocolor "START INSTALLING OPS DASHBOARD"
###################
sleep 5

echocolor "Installing Dashboard package"
apt-get -y install openstack-dashboard 
apt-get -y remove --auto-remove openstack-dashboard-ubuntu-theme

# echo "########## Fix bug in apache2 ##########"
# sleep 5
# Fix bug apache in ubuntu 14.04
# echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
# sudo a2enconf servername 

echocolor "Creating redirect page"

filehtml=/var/www/html/index.html
test -f $filehtml.orig || cp $filehtml $filehtml.orig
rm $filehtml
touch $filehtml
cat << EOF >> $filehtml
<html>
<head>
<META HTTP-EQUIV="Refresh" Content="0.5; URL=http://$CON_EXT_IP/horizon">
</head>
<body>
<center> <h1>Dang chuyen den Dashboard cua OpenStack</h1> </center>
</body>
</html>
EOF
# Allowing insert password in dashboard ( only apply in image )
sed -i "s/'can_set_password': False/'can_set_password': True/g" \
/etc/openstack-dashboard/local_settings.py

sed -i "s/_member_/user/g" /etc/openstack-dashboard/local_settings.py 


## /* Restarting apache2 and memcached
service apache2 restart
service memcached restart
echocolor "Finish setting up Horizon"

echocolor "LOGIN INFORMATION IN HORIZON"
echocolor "URL: http://$CTL_EXT_IP/horizon"
echocolor "User: admin or demo"
echocolor "Password:" $ADMIN_PASS