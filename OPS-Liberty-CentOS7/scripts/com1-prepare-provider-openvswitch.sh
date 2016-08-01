#!/bin/bash -ex
#

source config.cfg
source functions.sh
echocolor "Installing CRUDINI"
sleep 3
yum -y install crudini

echocolor "Configuring net forward for all VMs"
sleep 5
echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf
sysctl -p

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
yum -y install openstack-nova-compute sysfsutils openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch


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
ops_edit $nova_com DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
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
ops_edit $nova_com neutron metadata_proxy_shared_secret $METADATA_SECRET

echocolor "Restart and start nova-compute when reboot server"
sleep 5
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

echocolor "Install neutron-openvswitch-agent (neutron) on COMPUTE NODE"
sleep 5
yum -y install  openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch

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


############################## ml2_conf.ini ##############################
echocolor "Configuring ml2_conf.ini"
sleep 5
ml2_clt=/etc/neutron/plugins/ml2/ml2_conf.ini
test -f $ml2_clt.orig || cp $ml2_clt $ml2_clt.orig

## [ml2] section
ops_edit $ml2_clt ml2 type_drivers flat,vlan,gre,vxlan
ops_edit $ml2_clt ml2 tenant_network_types
ops_edit $ml2_clt ml2 mechanism_drivers openvswitch

## [ml2_type_flat] section
ops_edit $ml2_clt ml2_type_flat flat_networks physnet1

## [securitygroup] section
ops_edit $ml2_clt securitygroup enable_ipset True
ops_edit $ml2_clt securitygroup enable_security_group  True
ops_edit $ml2_clt securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

echocolor "Configuring openvswitch_agent"
sleep 5
########
ovsfile_com=/etc/neutron/plugins/ml2/openvswitch_agent.ini
test -f $ovsfile_com.orig || cp $ovsfile_com $ovsfile_com.orig

## [ovs] section
ops_edit $ovsfile_com ovs bridge_mappings  physnet1:br-eth1

## Create link 
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini 

# Edit interface 
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth1
TYPE=Ethernet
DEVICE="eth1"
NAME=eth1
ONBOOT=yes
OVS_BRIDGE=br-eth1
TYPE="OVSPort"
DEVICETYPE="ovs"
EOF

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-eth1
DEVICE="br-eth1"
BOOTPROTO="none"
IPADDR=$COM1_EXT_IP
PREFIX=$NETMASK_ADD_EXT
GATEWAY=$GATEWAY_IP_EXT
DNS1=$DNS_SERVER
ONBOOT="yes"
TYPE="OVSBridge"
DEVICETYPE="ovs"
EOF


echocolor "Reset service nova-compute,openvswitch"
sleep 5

systemctl start openvswitch
systemctl enable openvswitch 
systemctl restart openstack-nova-compute openstack-nova-metadata-api 
systemctl start neutron-openvswitch-agent
systemctl enable neutron-openvswitch-agent 

echocolor "Add port for OVS"
sleep 5
ovs-vsctl add-br br-int 
ovs-vsctl add-br br-eth1
ovs-vsctl add-port br-eth1 eth1 

echocolor "Reboot Server"
sleep 5
init 6
