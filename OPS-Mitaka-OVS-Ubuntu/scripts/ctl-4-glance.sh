#!/bin/bash -ex
#
source config.cfg
source functions.sh

echocolor "Create the database for GLANCE"
sleep 3

cat << EOF | mysql -uroot -p$MYSQL_PASS
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '$GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '$GLANCE_DBPASS';
FLUSH PRIVILEGES;
EOF



echocolor " Create user, endpoint for GLANCE"
sleep 3

openstack user create --password $GLANCE_PASS glance
openstack role add --project service --user glance admin

openstack service create --name glance \
--description "OpenStack Image service" image

openstack endpoint create \
--publicurl http://$CTL_MGNT_IP:9292 \
--internalurl http://$CTL_MGNT_IP:9292 \
--adminurl http://$CTL_MGNT_IP:9292 \
--region RegionOne \
image

echocolor "Install GLANCE"
sleep 5
apt-get -y install glance python-glanceclient


echocolor "Configuring GLANCE API"
sleep 5 
#/* Back-up file nova.conf
glanceapi_ctl=/etc/glance/glance-api.conf
test -f $glanceapi_ctl.orig || cp $glanceapi_ctl $glanceapi_ctl.orig

#Configuring glance config file /etc/glance/glance-api.conf

ops_edit $glanceapi_ctl database \
connection  mysql+pymysql://glance:$GLANCE_DBPASS@$CTL_MGNT_IP/glance
ops_del $glanceapi_ctl database sqlite_db

ops_edit $glanceapi_ctl keystone_authtoken \
auth_uri http://$CTL_MGNT_IP:5000

ops_edit $glanceapi_ctl keystone_authtoken \
auth_url http://$CTL_MGNT_IP:35357

ops_edit $glanceapi_ctl keystone_authtoken auth_plugin password
ops_edit $glanceapi_ctl keystone_authtoken project_domain_id default
ops_edit $glanceapi_ctl keystone_authtoken user_domain_id default
ops_edit $glanceapi_ctl keystone_authtoken project_name service
ops_edit $glanceapi_ctl keystone_authtoken username glance
ops_edit $glanceapi_ctl keystone_authtoken password $GLANCE_PASS

ops_edit $glanceapi_ctl paste_deploy flavor keystone

ops_edit $glanceapi_ctl glance_store default_store file
ops_edit $glanceapi_ctl glance_store \
filesystem_store_datadir /var/lib/glance/images/

ops_edit $glanceapi_ctl DEFAULT  notification_driver noop
ops_edit $glanceapi_ctl DEFAULT  verbose True


#
sleep 10
echocolor "Configuring GLANCE REGISTER"
#/* Backup file file glance-registry.conf
glancereg_ctl=/etc/glance/glance-registry.conf
test -f $glancereg_ctl.orig || cp $glancereg_ctl $glancereg_ctl.orig

ops_edit $glancereg_ctl database \
connection  mysql+pymysql://glance:$GLANCE_DBPASS@$CTL_MGNT_IP/glance
ops_del $glancereg_ctl database sqlite_db

ops_edit $glancereg_ctl keystone_authtoken \
auth_uri http://$CTL_MGNT_IP:5000

ops_edit $glancereg_ctl keystone_authtoken \
auth_url http://$CTL_MGNT_IP:35357

ops_edit $glancereg_ctl keystone_authtoken auth_plugin password
ops_edit $glancereg_ctl keystone_authtoken project_domain_id default
ops_edit $glancereg_ctl keystone_authtoken user_domain_id default
ops_edit $glancereg_ctl keystone_authtoken project_name service
ops_edit $glancereg_ctl keystone_authtoken username glance
ops_edit $glancereg_ctl keystone_authtoken password $GLANCE_PASS


ops_edit $glancereg_ctl paste_deploy flavor keystone


ops_edit $glancereg_ctl DEFAULT  notification_driver noop
ops_edit $glancereg_ctl DEFAULT  verbose True


# echocolor "########## Remove Glance default DB ##########"
# sleep 7
# rm /var/lib/glance/glance.sqlite

# chown glance:glance $glanceapi_ctl
# chown glance:glance $glancereg_ctl


echocolor "########## Syncing DB for Glance ##########"
sleep 7
glance-manage db_sync


echocolor "########## Restarting GLANCE service ... ##########"
sleep 5

service glance-registry restart
service glance-api restart
sleep 3

service glance-registry restart
service glance-api restart

#

echocolor "Remove glance.sqlite "
rm -f /var/lib/glance/glance.sqlite



echocolor "########## Registering Cirros IMAGE for GLANCE ... ##########"
sleep 3

mkdir images
cd images /
wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img

glance image-create --name "cirros" \
--file cirros-0.3.4-x86_64-disk.img \
--disk-format qcow2 --container-format bare \
--visibility public --progress
cd /root/
# rm -r /tmp/images


echocolor "########## Testing Glance ##########"
sleep 5
glance image-list
