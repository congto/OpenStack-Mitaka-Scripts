#!/bin/bash -ex
#

source config.cfg
source functions.sh

echocolor "Create DB for manila"
sleep 5
cat << EOF | mysql -uroot -p$MYSQL_PASS
CREATE DATABASE manila;

GRANT ALL PRIVILEGES ON manila.* TO 'manila'@'localhost' \
    IDENTIFIED BY '$MANILA_DBPASS';
GRANT ALL PRIVILEGES ON manila.* TO 'manila'@'%' \
    IDENTIFIED BY '$MANILA_DBPASS';
  
FLUSH PRIVILEGES;

EOF

echocolor "Create  user, endpoint for manila"
sleep 5
openstack user create manila --domain default --password $MANILA_PASS

openstack role add --project service --user manila admin

openstack service create --name manila \
    --description "OpenStack Shared File Systems" share
  
openstack service create --name manilav2 \
    --description "OpenStack Shared File Systems" sharev2
 
openstack endpoint create --region RegionOne \
    share public http://$CTL_MGNT_IP:8786/v1/%\(tenant_id\)s
    
openstack endpoint create --region RegionOne \
    share internal http://$CTL_MGNT_IP:8786/v1/%\(tenant_id\)s
  
openstack endpoint create --region RegionOne \
    share admin http://$CTL_MGNT_IP:8786/v1/%\(tenant_id\)s


openstack endpoint create --region RegionOne \
    sharev2 public http://$CTL_MGNT_IP:8786/v2/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
    sharev2 internal http://$CTL_MGNT_IP:8786/v2/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
    sharev2 admin http://$CTL_MGNT_IP:8786/v2/%\(tenant_id\)s
    
#
echocolor "Install manila"
sleep 3
apt-get -y install manila-api manila-scheduler \
    python-manilaclient

   
    

manila_ctl=/etc/manila/manila.conf
test -f $manila_ctl.orig || cp $manila_ctl $manila_ctl.orig
#cat /etc/manila/manila.conf.orig | egrep -v '^#|^$' > /etc/manila/manila.conf
    
## [DEFAULT] section
ops_edit $manila_ctl DEFAULT rpc_backend rabbit
ops_edit $manila_ctl DEFAULT auth_strategy keystone
ops_edit $manila_ctl DEFAULT my_ip $CTL_MGNT_IP
ops_edit $manila_ctl DEFAULT enabled_backends lvm
ops_edit $manila_ctl DEFAULT notification_driver messagingv2

ops_del $manila_ctl DEFAULT verbose

## [database] section
ops_edit $manila_ctl database \
connection mysql+pymysql://manila:$MANILA_DBPASS@$CTL_MGNT_IP/manila

## [oslo_messaging_rabbit] section
ops_edit $manila_ctl oslo_messaging_rabbit rabbit_host $CTL_MGNT_IP
ops_edit $manila_ctl oslo_messaging_rabbit rabbit_userid openstack
ops_edit $manila_ctl oslo_messaging_rabbit rabbit_password $RABBIT_PASS

## [keystone_authtoken] section
ops_edit $manila_ctl keystone_authtoken auth_uri http://$CTL_MGNT_IP:5000
ops_edit $manila_ctl keystone_authtoken auth_url http://$CTL_MGNT_IP:35357
ops_edit $manila_ctl keystone_authtoken memcached_servers $CTL_MGNT_IP:11211
ops_edit $manila_ctl keystone_authtoken auth_type password
ops_edit $manila_ctl keystone_authtoken project_domain_name default
ops_edit $manila_ctl keystone_authtoken user_domain_name default
ops_edit $manila_ctl keystone_authtoken project_name service
ops_edit $manila_ctl keystone_authtoken username manila
ops_edit $manila_ctl keystone_authtoken password $MANILA_PASS

## [oslo_concurrency] section
ops_edit $manila_ctl oslo_concurrency lock_path /var/lib/manila/tmp

## [lvm] section
# ops_edit $manila_ctl lvm \
#    volume_driver inder.volume.drivers.lvm.LVMVolumeDriver
# ops_edit $manila_ctl lvm volume_group manila-volumes
# ops_edit $manila_ctl lvm iscsi_protocol iscsi
# ops_edit $manila_ctl lvm iscsi_helper tgtadm

# [manila] Section
nova_ctl=/etc/nova/nova.conf
ops_edit $nova_ctl manila os_region_name RegionOne

echocolor "Syncing manila DB"
sleep 3
su -s /bin/sh -c "manila-manage db sync" manila


echocolor "Restarting nova-api service"
sleep 3
service nova-api restart


echocolor "Restarting manila service"
sleep 3
service manila-api restart
service manila-scheduler restart

rm -f /var/lib/manila/manila.sqlite

echocolor "Finish setting up manila"
