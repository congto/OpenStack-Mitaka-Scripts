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
 
echo "manual" > /etc/init/keystone.override
 

apt-get -y install keystone apache2 libapache2-mod-wsgi \
        memcached python-memcache
  
# Back-up file nova.conf
filekeystone=/etc/keystone/keystone.conf
test -f $filekeystone.orig || cp $filekeystone $filekeystone.orig
 
#Config file /etc/keystone/keystone.conf
ops_edit $filekeystone DEFAULT admin_token $TOKEN_PASS
ops_edit $filekeystone DEFAULT verbose True
ops_edit $filekeystone database \
connection mysql+pymysql://keystone:$KEYSTONE_DBPASS@$CTL_MGNT_IP/keystone

ops_edit $filekeystone memcache servers localhost:11211
ops_edit $filekeystone token provider uuid
ops_edit $filekeystone token driver memcache
ops_edit $filekeystone revoke driver sql

#
su -s /bin/sh -c "keystone-manage db_sync" keystone
 
echo "ServerName $CTL_MGNT_IP" >>  /etc/apache2/apache2.conf

 
cat << EOF > /etc/apache2/sites-available/wsgi-keystone.conf
Listen 5000
Listen 35357

<VirtualHost *:5000>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

<VirtualHost *:35357>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

 
EOF
 
ln -s /etc/apache2/sites-available/wsgi-keystone.conf \
	/etc/apache2/sites-enabled
 
service apache2 restart

rm -f /var/lib/keystone/keystone.db

export OS_TOKEN="$TOKEN_PASS"
export OS_URL=http://$CTL_MGNT_IP:35357/v2.0
 
 
###  Identity service
openstack service create \
--name keystone --description "OpenStack Identity" identity

### Create the Identity service API endpoint
openstack endpoint create \
--publicurl http://$CTL_MGNT_IP:5000/v2.0 \
--internalurl http://$CTL_MGNT_IP:5000/v2.0 \
--adminurl http://$CTL_MGNT_IP:35357/v2.0 \
--region RegionOne \
identity
 
#### To create tenants, users, and roles ADMIN
openstack project create --description "Admin Project" admin
openstack user create --password  $ADMIN_PASS admin
openstack role create admin
openstack role add --project admin --user admin admin
 
#### To create tenants, users, and roles  SERVICE
openstack project create --description "Service Project" service
 
 
#### To create tenants, users, and roles  DEMO
openstack project create --description "Demo Project" demo
openstack user create --password $ADMIN_PASS demo
 
### Create the user role
openstack role create user
openstack role add --project demo --user demo user
 
#################
 
unset OS_TOKEN OS_URL
 
# Tao bien moi truong
 
cat << EOF > admin-openrc.sh
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$CTL_MGNT_IP:35357/v3
export OS_VOLUME_API_VERSION=2
EOF

sleep 5
echocolor "Execute environment script"
chmod +x admin-openrc.sh
cat  admin-openrc.sh >> /etc/profile
cp  admin-openrc.sh /root/admin-openrc.sh
source admin-openrc.sh


cat << EOF > demo-openrc.sh
export OS_PROJECT_DOMAIN_ID=default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_NAME=demo
export OS_TENANT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=$ADMIN_PASS
export OS_AUTH_URL=http://$CTL_MGNT_IP:35357/v3
export OS_VOLUME_API_VERSION=2
EOF

chmod +x demo-openrc.sh
cp  demo-openrc.sh /root/demo-openrc.sh
