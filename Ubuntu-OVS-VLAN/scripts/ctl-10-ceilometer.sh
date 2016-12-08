#!/bin/bash -ex
source config.cfg
source functions.sh

apt-get install -y mongodb-server mongodb-clients python-pymongo

sed -i "s/bind_ip = 127.0.0.1/bind_ip = $CON_MGNT_IP/g" /etc/mongodb.conf
service mongodb restart
sleep 40
cat << EOF > mongo.js
  db = db.getSiblingDB("ceilometer");
  db.addUser({user: "ceilometer",
  pwd: "$CEILOMETER_DBPASS",
  roles: [ "readWrite", "dbAdmin" ]})
EOF
sleep 20
mongo --host $CTL_MGNT_IP ./mongo.js

## Create user, end point and assign role for Ceilometer

openstack user create  --domain default --password $CEILOMETER_PASS ceilometer
openstack role add --project service --user ceilometer admin
openstack service create --name ceilometer --description "Telemetry" metering

openstack endpoint create --region RegionOne \
    metering public http://$CTL_MGNT_IP:8777

openstack endpoint create --region RegionOne \
    metering internal http://$CTL_MGNT_IP:8777

openstack endpoint create --region RegionOne \
    metering admin http://$CTL_MGNT_IP:8777

# Install ceilometer dependencies
apt-get install -y ceilometer-api ceilometer-collector \
    ceilometer-agent-central ceilometer-agent-notification \
    python-ceilometerclient

echocolor "Config ceilometer"
sleep 5

ceilometer_ctl=/etc/ceilometer/ceilometer.conf
test -f $ceilometer_ctl.orig || cp $ceilometer_ctl $ceilometer_ctl.orig

## [DEFAULT] section
ops_edit $ceilometer_ctl DEFAULT verbose True
ops_edit $ceilometer_ctl DEFAULT rpc_backend rabbit
ops_edit $ceilometer_ctl DEFAULT auth_strategy keystone

## [database] section
ops_edit $ceilometer_ctl database connection \
    mongodb://ceilometer:$CEILOMETER_DBPASS@$CTL_MGNT_IP:27017/ceilometer

## [keystone_authtoken] section
ops_edit $ceilometer_ctl keystone_authtoken auth_uri http://$CTL_MGNT_IP:5000
ops_edit $ceilometer_ctl keystone_authtoken auth_url http://$CTL_MGNT_IP:35357
ops_edit $ceilometer_ctl keystone_authtoken auth_type password
ops_edit $ceilometer_ctl keystone_authtoken project_domain_id default
ops_edit $ceilometer_ctl keystone_authtoken user_domain_id default
ops_edit $ceilometer_ctl keystone_authtoken project_name service
ops_edit $ceilometer_ctl keystone_authtoken username ceilometer
ops_edit $ceilometer_ctl keystone_authtoken password $CEILOMETER_PASS


## [service_credentials] section
ops_edit $ceilometer_ctl service_credentials \
os_auth_url http://$CTL_MGNT_IP:5000/v2.0
ops_edit $ceilometer_ctl service_credentials os_username ceilometer
ops_edit $ceilometer_ctl service_credentials os_tenant_name service
ops_edit $ceilometer_ctl service_credentials os_password $CEILOMETER_PASS
ops_edit $ceilometer_ctl service_credentials os_endpoint_type internalURL
ops_edit $ceilometer_ctl service_credentials os_region_name RegionOne


## [oslo_messaging_rabbit] section
ops_edit $ceilometer_ctl oslo_messaging_rabbit rabbit_host $CTL_MGNT_IP
ops_edit $ceilometer_ctl oslo_messaging_rabbit rabbit_userid openstack
ops_edit $ceilometer_ctl oslo_messaging_rabbit rabbit_password $RABBIT_PASS

EOF

echocolor "Restart service"
sleep 3
service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
service ceilometer-alarm-evaluator restart
service ceilometer-alarm-notifier restart

echo "Restart service"
sleep 10
service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
service ceilometer-alarm-evaluator restart
service ceilometer-alarm-notifier restart
