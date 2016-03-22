#!/bin/bash -ex
#
source config.cfg
source functions.sh

echocolor "Create DB for NOVA "
cat << EOF | mysql -uroot -p$MYSQL_PASS
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '$NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '$NOVA_DBPASS';
FLUSH PRIVILEGES;
EOF


echocolor "Creat user, endpoint for NOVA"

openstack user create --password $NOVA_PASS nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute

openstack endpoint create \
--publicurl http://$CTL_MGNT_IP:8774/v2/%\(tenant_id\)s \
--internalurl http://$CTL_MGNT_IP:8774/v2/%\(tenant_id\)s \
--adminurl http://$CTL_MGNT_IP:8774/v2/%\(tenant_id\)s \
--region RegionOne \
compute


echocolor "Install NOVA in $CTL_MGNT_IP"
sleep 5 
apt-get -y install nova-api nova-cert nova-conductor \
           nova-consoleauth nova-novncproxy nova-scheduler \
           python-novaclient

# Cai tu dong libguestfs-tools 
echo "libguestfs-tools        libguestfs/update-appliance     boolean true"  | debconf-set-selections
apt-get -y install libguestfs-tools sysfsutils guestfsd python-guestfs

######## Backup configurations for NOVA ##########"
sleep 7

#
nova_ctl=/etc/nova/nova.conf
test -f $nova_ctl.orig || cp $nova_ctl $nova_ctl.orig

echocolor "Config file nova.conf"
sleep 5

ops_edit $nova_ctl DEFAULT verbose True
ops_edit $nova_ctl DEFAULT rpc_backend rabbit
ops_edit $nova_ctl DEFAULT auth_strategy keystone
ops_edit $nova_ctl DEFAULT my_ip $CTL_MGNT_IP
ops_edit $nova_ctl DEFAULT \
network_api_class nova.network.neutronv2.api.API

ops_edit $nova_ctl DEFAULT security_group_api neutron

ops_edit $nova_ctl DEFAULT \
linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver

ops_edit $nova_ctl DEFAULT \
firewall_driver nova.virt.firewall.NoopFirewallDriver

ops_edit $nova_ctl DEFAULT \
enabled_apis osapi_compute,metadata

ops_edit $nova_ctl database \
connection mysql+pymysql://nova:$NOVA_DBPASS@$CTL_MGNT_IP/nova

ops_edit $nova_ctl oslo_messaging_rabbit rabbit_host $CTL_MGNT_IP
ops_edit $nova_ctl oslo_messaging_rabbit rabbit_userid openstack
ops_edit $nova_ctl oslo_messaging_rabbit rabbit_password $RABBIT_PASS

ops_edit $nova_ctl keystone_authtoken auth_uri $http://$CTL_MGNT_IP:5000
ops_edit $nova_ctl keystone_authtoken auth_url http://$CTL_MGNT_IP:35357
ops_edit $nova_ctl keystone_authtoken auth_plugin password
ops_edit $nova_ctl keystone_authtoken project_domain_id default
ops_edit $nova_ctl keystone_authtoken user_domain_id default
ops_edit $nova_ctl keystone_authtoken project_name service
ops_edit $nova_ctl keystone_authtoken username nova
ops_edit $nova_ctl keystone_authtoken password $NOVA_PASS

ops_edit $nova_ctl vnc vncserver_listen \$my_ip
ops_edit $nova_ctl vnc vncserver_proxyclient_address \$my_ip

ops_edit $nova_ctl glance host $CTL_MGNT_IP

ops_edit $nova_ctl oslo_concurrency lock_path /var/lib/nova/tmp

ops_edit $nova_ctl neutron url http://$CTL_MGNT_IP:9696
ops_edit $nova_ctl neutron auth_url http://$CTL_MGNT_IP:35357
ops_edit $nova_ctl neutron auth_plugin password
ops_edit $nova_ctl neutron project_domain_id default
ops_edit $nova_ctl neutron user_domain_id default
ops_edit $nova_ctl neutron region_name RegionOne
ops_edit $nova_ctl neutron project_name service
ops_edit $nova_ctl neutron username neutron
ops_edit $nova_ctl neutron password $NEUTRON_PASS
ops_edit $nova_ctl neutron service_metadata_proxy True
ops_edit $nova_ctl neutron metadata_proxy_shared_secret $METADATA_SECRET

## [cinder] Section 
ops_edit $nova_ctl cinder os_region_name RegionOne


echocolor "Remove Nova default db "
sleep 7
rm /var/lib/nova/nova.sqlite

echocolor "Syncing Nova DB"
sleep 7 
su -s /bin/sh -c "nova-manage db sync" nova

echocolor "Restarting NOVA "
sleep 7 
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

sleep 7 
echocolor "Restarting NOVA"
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

echocolor "Testing NOVA service"
nova-manage service list

