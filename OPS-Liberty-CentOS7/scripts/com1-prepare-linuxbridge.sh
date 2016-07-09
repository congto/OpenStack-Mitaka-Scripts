#!/bin/bash -ex
#

source config.cfg
source functions.sh
echocolor "Installing CRUDINI"
sleep 3
yum -y install crudini

# echocolor "Configuring net forward for all VMs"
# sleep 5
# echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf
# echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
# sysctl -p

###########################################################
echocolor "Install and config NTP"
sleep 3
yum -y install chrony
ntpfile=/etc/chrony.conf
cp $ntpfile $ntpfile.orig

echo "server $CTL_MGNT_IP iburst" >> $ntpfile

echocolor "Start the NTP service"
sleep 3
systemctl enable chronyd.service
systemctl start chronyd.service

echocolor "Check service NTP"
sleep 3
chronyc sources

sleep 5
echocolor "Installl package for NOVA"
yum -y install openstack-nova-compute sysfsutils 

echocolor "Install & Configuring in nova.conf"
sleep 5
#Backup nova.conf
nova_com=/etc/nova/nova.conf
test -f $nova_com.orig || cp $nova_com $nova_com.orig

## [DEFAULT] Section
ops_edit $nova_com DEFAULT my_ip $COM1_MGNT_IP
ops_edit $nova_com DEFAULT auth_strategy keystone
ops_edit $nova_com DEFAULT rpc_backend rabbit


ops_edit $nova_com DEFAULT network_api_class nova.network.neutronv2.api.API
ops_edit $nova_com DEFAULT security_group_api neutron
ops_edit $nova_com DEFAULT linuxnet_interface_driver nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
ops_edit $nova_com DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
ops_edit $nova_com DEFAULT memcached_servers $CTL_MGNT_IP:11211


## [oslo_messaging_rabbit] section
ops_edit $nova_com oslo_messaging_rabbit rabbit_host $CTL_MGNT_IP
ops_edit $nova_com oslo_messaging_rabbit rabbit_userid openstack
ops_edit $nova_com oslo_messaging_rabbit rabbit_password $RABBIT_PASS

## [keystone_authtoken] section
ops_edit $nova_com keystone_authtoken auth_uri http://$CTL_MGNT_IP:5000
ops_edit $nova_com keystone_authtoken auth_url http://$CTL_MGNT_IP:35357
ops_edit $nova_com keystone_authtoken auth_plugin password
ops_edit $nova_com keystone_authtoken project_domain_id default
ops_edit $nova_com keystone_authtoken user_domain_id default
ops_edit $nova_com keystone_authtoken project_name service
ops_edit $nova_com keystone_authtoken username nova
ops_edit $nova_com keystone_authtoken password $NOVA_PASS

## [vnc] section
ops_edit $nova_com vnc enabled True
ops_edit $nova_com vnc vncserver_listen 0.0.0.0
ops_edit $nova_com vnc vncserver_proxyclient_address \$my_ip
ops_edit $nova_com vnc novncproxy_base_url http://$CTL_EXT_IP:6080/vnc_auto.html

## [glance] section
ops_edit $nova_com glance host $CTL_MGNT_IP


## [oslo_concurrency] section
ops_edit $nova_com oslo_concurrency lock_path /var/lib/nova/tmp

## [neutron] section
ops_edit $nova_com neutron url http://$CTL_MGNT_IP:9696
ops_edit $nova_com neutron auth_url http://$CTL_MGNT_IP:35357
ops_edit $nova_com neutron auth_plugin password
ops_edit $nova_com neutron project_domain_id default
ops_edit $nova_com neutron user_domain_id default
ops_edit $nova_com neutron region_name RegionOne
ops_edit $nova_com neutron project_name service
ops_edit $nova_com neutron username neutron
ops_edit $nova_com neutron password $NEUTRON_PASS
ops_edit $nova_com neutron service_metadata_proxy True
ops_edit $nova_com neutron metadata_proxy_shared_secret metadata_secret

echocolor "Restart and start nova-compute when reboot server"
sleep 5
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

echocolor "Install neutron-linuxbridge-agent (neutron) on COMPUTE NODE"
sleep 5
yum -y install  openstack-neutron-linuxbridge ebtables ipset

echocolor "Config file neutron.conf"
neutron_com=/etc/neutron/neutron.conf
test -f $neutron_com.orig || cp $neutron_com $neutron_com.orig

## [DEFAULT] section

ops_edit $neutron_com DEFAULT auth_strategy keystone
ops_edit $neutron_com DEFAULT verbose True
ops_edit $neutron_com DEFAULT core_plugin ml2
ops_edit $neutron_com DEFAULT service_plugins router
ops_edit $neutron_com DEFAULT allow_overlapping_ips  True
ops_edit $neutron_com DEFAULT rpc_backend rabbit

## [keystone_authtoken] section
ops_edit $neutron_com keystone_authtoken auth_uri http://$CTL_MGNT_IP:5000
ops_edit $neutron_com keystone_authtoken auth_url http://$CTL_MGNT_IP:35357
ops_edit $neutron_com keystone_authtoken auth_plugin password
ops_edit $neutron_com keystone_authtoken project_domain_id default
ops_edit $neutron_com keystone_authtoken user_domain_id default
ops_edit $neutron_com keystone_authtoken project_name service
ops_edit $neutron_com keystone_authtoken username neutron
ops_edit $neutron_com keystone_authtoken password $NEUTRON_PASS

ops_del $neutron_ctl keystone_authtoken identity_uri
ops_del $neutron_ctl keystone_authtoken admin_tenant_name
ops_del $neutron_ctl keystone_authtoken admin_user
ops_del $neutron_ctl keystone_authtoken admin_password

## [database] section
ops_del $neutron_com database connection

## [oslo_messaging_rabbit] section
ops_edit $neutron_com oslo_messaging_rabbit rabbit_host $CTL_MGNT_IP
ops_edit $neutron_com oslo_messaging_rabbit rabbit_userid openstack
ops_edit $neutron_com oslo_messaging_rabbit rabbit_password $RABBIT_PASS

## [oslo_concurrency] section
ops_edit $neutron_com oslo_concurrency lock_path /var/lib/neutron/tmp


echocolor "Configuring linuxbridge_agent"
sleep 5
########
lbfile_com=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
test -f $lbfile_com.orig || cp $lbfile_com $lbfile_com.orig

## [linux_bridge] section
ops_edit $lbfile_com linux_bridge physical_interface_mappings public:eth1

# [vxlan] section
ops_edit $lbfile_com vxlan enable_vxlan False

# [securitygroup] section
ops_edit $lbfile_com securitygroup enable_security_group True
ops_edit $lbfile_com securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

## Create link 
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini 


echocolor "Reset service nova-compute,linuxbridge"
sleep 5

systemctl restart openstack-nova-compute.service
systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service

echocolor "Reboot Server"
sleep 5
init 6
