#!/bin/bash -ex
#
source config.cfg
source functions.sh

echocolor "Create Database for Keystone"

cat << EOF | mysql -uroot -p$MYSQL_PASS
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$KEYSTONE_DBPASS';
FLUSH PRIVILEGES;
EOF

echocolor "Install keystone"

yum -y install openstack-keystone httpd mod_wsgi


# Back-up file keystone.conf
filekeystone=/etc/keystone/keystone.conf
test -f $filekeystone.orig || cp $filekeystone $filekeystone.orig

# Config file /etc/keystone/keystone.conf
ops_edit $filekeystone DEFAULT admin_token $TOKEN_PASS
ops_edit $filekeystone database \
connection mysql+pymysql://keystone:$KEYSTONE_DBPASS@$CTL_MGNT_IP/keystone

ops_edit $filekeystone token provider fernet

#
su -s /bin/sh -c "keystone-manage db_sync" keystone

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone

echo "ServerName $CTL_MGNT_IP" >>   /etc/httpd/conf/httpd.conf

cat << EOF > /etc/httpd/conf.d/wsgi-keystone.conf
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    ErrorLogFormat "%{cu}t %M"
    ErrorLog /var/log/httpd/keystone-error.log
    CustomLog /var/log/httpd/keystone-access.log combined

    <Directory /usr/bin>
        Require all granted
    </Directory>
</VirtualHost>
EOF

echocolor "Restart httpd"
sleep 3
systemctl enable httpd.service
systemctl start httpd.service

rm -f /var/lib/keystone/keystone.db

export OS_TOKEN="$TOKEN_PASS"
export OS_URL=http://$CTL_MGNT_IP:35357/v3
export OS_IDENTITY_API_VERSION=3

###  Identity service
openstack service create \
    --name keystone --description "OpenStack Identity" identity


openstack endpoint create --region RegionOne \
identity public http://$CTL_MGNT_IP:5000/v3

openstack endpoint create --region RegionOne \
identity internal http://$CTL_MGNT_IP:5000/v3

openstack endpoint create --region RegionOne \
identity admin http://$CTL_MGNT_IP:35357/v3

openstack domain create --description "Default Domain" default

openstack project create --domain default --description "Admin Project" admin

openstack user create admin --domain default --password $ADMIN_PASS

openstack role create admin

openstack role add --project admin --user admin admin

openstack project create --domain default \
    --description "Service Project" service

openstack project create --domain default --description "Demo Project" demo

openstack user create demo --domain default --password $ADMIN_PASS

openstack role create user

openstack role add --project demo --user demo user

unset OS_TOKEN OS_URL

# Create environment file
cat << EOF > admin-openrc
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$CTL_MGNT_IP:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

sleep 5
echocolor "Execute environment script"
chmod +x admin-openrc
cat  admin-openrc >> /etc/profile
cp  admin-openrc /root/admin-openrc
source admin-openrc


cat << EOF > demo-openrc
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$DEMO_PASS
export OS_AUTH_URL=http://$CTL_MGNT_IP:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
chmod +x demo-openrc
cp  demo-openrc /root/demo-openrc

echocolor "Verifying keystone"
openstack token issue
