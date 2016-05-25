#!/bin/bash -ex
#

source config.cfg
source functions.sh

apt-get -y install python-pip
pip install \
    https://pypi.python.org/packages/source/c/crudini/crudini-0.7.tar.gz

#
echocolor "Install CINDER"
sleep 3
apt-get install -y lvm2 cinder-volume python-mysqldb

pvcreate /dev/vdb
vgcreate cinder-volumes /dev/vdb
sed  -r -i 's#(filter = )(\[ "a/\.\*/" \])#\1["a\/vdb\/", "r/\.\*\/"]#g' \
    /etc/lvm/lvm.conf

cinder_ctl=/etc/cinder/cinder.conf
test -f $cinder_ctl.orig || cp $cinder_ctl $cinder_ctl.orig

## [DEFAULT] section
ops_edit $cinder_ctl DEFAULT rpc_backend rabbit
ops_edit $cinder_ctl DEFAULT auth_strategy keystone
ops_edit $cinder_ctl DEFAULT my_ip $CIN_MGNT_IP
ops_edit $cinder_ctl DEFAULT verbose True
ops_edit $cinder_ctl DEFAULT enabled_backends lvm
ops_edit $cinder_ctl DEFAULT glance_api_servers  http://$CTL_MGNT_IP:9292
ops_edit $cinder_ctl DEFAULT notification_driver messagingv2

ops_del $cinder_ctl DEFAULT verbose

## [database] section
ops_edit $cinder_ctl database \
connection mysql+pymysql://cinder:$CINDER_DBPASS@$CTL_MGNT_IP/cinder

## [oslo_messaging_rabbit] section
ops_edit $cinder_ctl oslo_messaging_rabbit rabbit_host $CTL_MGNT_IP
ops_edit $cinder_ctl oslo_messaging_rabbit rabbit_userid openstack
ops_edit $cinder_ctl oslo_messaging_rabbit rabbit_password $RABBIT_PASS

## [keystone_authtoken] section
ops_edit $cinder_ctl keystone_authtoken auth_uri http://$CTL_MGNT_IP:5000
ops_edit $cinder_ctl keystone_authtoken auth_url http://$CTL_MGNT_IP:35357
ops_edit $cinder_ctl keystone_authtoken memcached_servers $CTL_MGNT_IP:11211
ops_edit $cinder_ctl keystone_authtoken auth_type password
ops_edit $cinder_ctl keystone_authtoken project_domain_name default
ops_edit $cinder_ctl keystone_authtoken user_domain_name default
ops_edit $cinder_ctl keystone_authtoken project_name service
ops_edit $cinder_ctl keystone_authtoken username cinder
ops_edit $cinder_ctl keystone_authtoken password $CINDER_PASS

## [oslo_concurrency] section
ops_edit $cinder_ctl oslo_concurrency lock_path /var/lib/cinder/tmp

## [lvm] section
ops_edit $cinder_ctl lvm \
    volume_driver cinder.volume.drivers.lvm.LVMVolumeDriver
ops_edit $cinder_ctl lvm volume_group cinder-volumes
ops_edit $cinder_ctl lvm iscsi_protocol iscsi
ops_edit $cinder_ctl lvm iscsi_helper tgtadm


echocolor "Restarting CINDER service"
sleep 3
service tgt restart
service cinder-volume restart

echocolor "Finish setting up CINDER"
