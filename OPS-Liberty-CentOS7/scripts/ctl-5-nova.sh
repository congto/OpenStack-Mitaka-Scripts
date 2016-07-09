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

echocolor "Create user, endpoint for NOVA"

openstack user create nova --domain default  --password $NOVA_PASS

openstack role add --project service --user nova admin

openstack service create --name nova --description "OpenStack Compute" compute

openstack endpoint create --region RegionOne \
    compute public http://$CTL_MGNT_IP:8774/v2.1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
    compute internal http://$CTL_MGNT_IP:8774/v2.1/%\(tenant_id\)s

openstack endpoint create --region RegionOne \
    compute admin http://$CTL_MGNT_IP:8774/v2.1/%\(tenant_id\)s


echocolor "Install NOVA in $CTL_MGNT_IP"
sleep 3
yum -y install openstack-nova-api openstack-nova-cert \
  openstack-nova-conductor openstack-nova-console \
  openstack-nova-novncproxy openstack-nova-scheduler \
  python-novaclient

######## Backup configurations for NOVA ##########"
sleep 7

#
nova_ctl=/etc/nova/nova.conf
test -f $nova_ctl.orig || cp $nova_ctl $nova_ctl.orig

echocolor "Config file nova.conf"
sleep 5

# [DEFAULT] Section


ops_edit $nova_ctl DEFAULT rpc_backend rabbit
ops_edit $nova_ctl DEFAULT auth_strategy keystone
ops_edit $nova_ctl DEFAULT my_ip $CTL_MGNT_IP
ops_edit $nova_ctl DEFAULT network_api_class nova.network.neutronv2.api.API
ops_edit $nova_ctl DEFAULT security_group_api neutron
ops_edit $nova_ctl DEFAULT linuxnet_interface_driver nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
ops_edit $nova_ctl DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
ops_edit $nova_ctl DEFAULT enabled_apis osapi_compute,metadata
ops_edit $nova_ctl DEFAULT verbose True


# [database] section
ops_edit $nova_ctl database connection mysql+pymysql://nova:$NOVA_DBPASS@$CTL_MGNT_IP/nova

# [oslo_messaging_rabbit] Section
ops_edit $nova_ctl oslo_messaging_rabbit rabbit_host $CTL_MGNT_IP
ops_edit $nova_ctl oslo_messaging_rabbit rabbit_userid openstack
ops_edit $nova_ctl oslo_messaging_rabbit rabbit_password $RABBIT_PASS

# [keystone_authtoken] section
ops_edit $nova_ctl keystone_authtoken auth_uri http://$CTL_MGNT_IP:5000
ops_edit $nova_ctl keystone_authtoken auth_url http://$CTL_MGNT_IP:35357
ops_edit $nova_ctl keystone_authtoken auth_plugin password
ops_edit $nova_ctl keystone_authtoken project_domain_id default
ops_edit $nova_ctl keystone_authtoken user_domain_id default
ops_edit $nova_ctl keystone_authtoken project_name service
ops_edit $nova_ctl keystone_authtoken username nova
ops_edit $nova_ctl keystone_authtoken password $NOVA_PASS

# [vnc] section
ops_edit $nova_ctl vnc vncserver_listen \$my_ip
ops_edit $nova_ctl vnc vncserver_proxyclient_address \$my_ip

# [glance] section
ops_edit $nova_ctl glance host $CTL_MGNT_IP

# [oslo_concurrency] section
ops_edit $nova_ctl oslo_concurrency lock_path /var/lib/nova/tmp

# [neutron] section
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

# [cinder] Section
ops_edit $nova_ctl cinder os_region_name RegionOne

##########
echocolor "Syncing Nova DB"
sleep 5
su -s /bin/sh -c "nova-manage db sync" nova

echocolor "Restarting NOVA "
sleep 7
systemctl enable openstack-nova-api.service \
  openstack-nova-cert.service openstack-nova-consoleauth.service \
  openstack-nova-scheduler.service openstack-nova-conductor.service \
  openstack-nova-novncproxy.service

sleep 3
systemctl start openstack-nova-api.service \
  openstack-nova-cert.service openstack-nova-consoleauth.service \
  openstack-nova-scheduler.service openstack-nova-conductor.service \
  openstack-nova-novncproxy.service

echocolor "Testing NOVA service"
sleep 3
nova service-list
