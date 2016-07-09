#!/bin/bash -ex
#
# RABBIT_PASS=
# ADMIN_PASS=

source config.cfg
source functions.sh

echocolor "Configuring net forward for all VMs"
sleep 5
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf 
echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf 
echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf 
sysctl -p

echocolor "Create DB for NEUTRON "
sleep 5
cat << EOF | mysql -uroot -p$MYSQL_PASS
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY '$NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY '$NEUTRON_DBPASS';
FLUSH PRIVILEGES;
EOF


echocolor "Create  user, endpoint for NEUTRON"
sleep 5

openstack user create neutron --domain default --password $NEUTRON_PASS

openstack role add --project service --user neutron admin

openstack service create --name neutron \
    --description "OpenStack Networking" network

openstack endpoint create --region RegionOne \
    network public http://$CTL_MGNT_IP:9696

openstack endpoint create --region RegionOne \
    network internal http://$CTL_MGNT_IP:9696

openstack endpoint create --region RegionOne \
    network admin http://$CTL_MGNT_IP:9696

# SERVICE_TENANT_ID=`keystone tenant-get service | awk '$2~/^id/{print $4}'`

echocolor "Install NEUTRON node - Using openvswitch"
sleep 5
yum -y install  openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch
  

######## Backup configuration NEUTRON.CONF ##################"
echocolor "Config NEUTRON"
sleep 5

#
neutron_ctl=/etc/neutron/neutron.conf
test -f $neutron_ctl.orig || cp $neutron_ctl $neutron_ctl.orig

## [DEFAULT] section
ops_edit $neutron_ctl DEFAULT core_plugin ml2
ops_edit $neutron_ctl DEFAULT service_plugins router
ops_edit $neutron_ctl DEFAULT auth_strategy keystone
ops_edit $neutron_ctl DEFAULT dhcp_agent_notification True
ops_edit $neutron_ctl DEFAULT allow_overlapping_ips True
ops_edit $neutron_ctl DEFAULT notify_nova_on_port_status_changes True
ops_edit $neutron_ctl DEFAULT notify_nova_on_port_data_changes True
ops_edit $neutron_ctl DEFAULT rpc_backend rabbit
ops_edit $neutron_ctl DEFAULT verbose True

## [database] section
ops_edit $neutron_ctl database connection mysql+pymysql://neutron:$NEUTRON_DBPASS@$CTL_MGNT_IP/neutron

## [keystone_authtoken] section
ops_edit $neutron_ctl keystone_authtoken auth_uri http://$CTL_MGNT_IP:5000
ops_edit $neutron_ctl keystone_authtoken auth_url http://$CTL_MGNT_IP:35357
ops_edit $neutron_ctl keystone_authtoken auth_plugin password
ops_edit $neutron_ctl keystone_authtoken project_domain_id default
ops_edit $neutron_ctl keystone_authtoken user_domain_id default
ops_edit $neutron_ctl keystone_authtoken project_name service
ops_edit $neutron_ctl keystone_authtoken username neutron
ops_edit $neutron_ctl keystone_authtoken password $NEUTRON_PASS

ops_del $neutron_ctl keystone_authtoken identity_uri
ops_del $neutron_ctl keystone_authtoken admin_tenant_name
ops_del $neutron_ctl keystone_authtoken admin_user
ops_del $neutron_ctl keystone_authtoken admin_password

## [oslo_messaging_rabbit] section
ops_edit $neutron_ctl oslo_messaging_rabbit rabbit_host $CTL_MGNT_IP
ops_edit $neutron_ctl oslo_messaging_rabbit rabbit_port 5672
ops_edit $neutron_ctl oslo_messaging_rabbit rabbit_userid openstack
ops_edit $neutron_ctl oslo_messaging_rabbit rabbit_password $RABBIT_PASS

## [nova] section
ops_edit $neutron_ctl nova auth_url http://$CTL_MGNT_IP:35357
ops_edit $neutron_ctl nova auth_plugin password
ops_edit $neutron_ctl nova project_domain_id default
ops_edit $neutron_ctl nova user_domain_id default
ops_edit $neutron_ctl nova region_name RegionOne
ops_edit $neutron_ctl nova project_name service
ops_edit $neutron_ctl nova username nova
ops_edit $neutron_ctl nova password $NOVA_PASS


####################### Backup configuration of ML2 ################################
echocolor "Configuring ML2"
sleep 7

ml2_clt=/etc/neutron/plugins/ml2/ml2_conf.ini
test -f $ml2_clt.orig || cp $ml2_clt $ml2_clt.orig

## [ml2] section
ops_edit $ml2_clt ml2 type_drivers flat,vlan,gre,vxlan
ops_edit $ml2_clt ml2 tenant_network_types
ops_edit $ml2_clt ml2 mechanism_drivers openvswitch
ops_edit $ml2_clt ml2 extension_drivers port_security

## [ml2_type_flat] section
ops_edit $ml2_clt ml2_type_flat flat_networks physnet1

## [securitygroup] section
ops_edit $ml2_clt securitygroup enable_ipset True
ops_edit $ml2_clt securitygroup enable_security_group True
ops_edit $ml2_clt securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

####################### Backup configuration of openvswitch_agent ################################
echocolor "Configuring openvswitch_agent"
sleep 5
ovsfile=/etc/neutron/plugins/ml2/openvswitch_agent.ini
test -f $ovsfile.orig || cp $ovsfile $ovsfile.orig

# [ovs] section
ops_edit $ovsfile ovs bridge_mappings physnet1:br-eth1

####################### Configuring  L3 AGENT ################################
netl3=/etc/neutron/l3_agent.ini
test -f $netl3.orig || cp $netl3 $netl3.orig

ops_edit $netl3 DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
ops_edit $netl3 DEFAULT external_network_bridge


####################### Configuring DHCP AGENT ################################
echocolor "Configuring DHCP AGENT"
sleep 7
#
netdhcp=/etc/neutron/dhcp_agent.ini
test -f $netdhcp.orig || cp $netdhcp $netdhcp.orig

## [DEFAULT] section
ops_edit $netdhcp DEFAULT interface_driver neutron.agent.linux.interface.OVSInterfaceDriver
ops_edit $netdhcp DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq

####################### Configuring METADATA AGENT ################################
echocolor "Configuring METADATA AGENT"
sleep 7
netmetadata=/etc/neutron/metadata_agent.ini
test -f $netmetadata.orig || cp $netmetadata $netmetadata.orig

## [DEFAULT]

ops_edit $netmetadata DEFAULT auth_uri http://$CTL_MGNT_IP:5000
ops_edit $netmetadata DEFAULT auth_url http://$CTL_MGNT_IP:35357
ops_edit $netmetadata DEFAULT auth_region  RegionOne
ops_edit $netmetadata DEFAULT auth_plugin  password
ops_edit $netmetadata DEFAULT project_domain_id  default
ops_edit $netmetadata DEFAULT user_domain_id  default
ops_edit $netmetadata DEFAULT project_name  service
ops_edit $netmetadata DEFAULT username  neutron
ops_edit $netmetadata DEFAULT password  $NEUTRON_PASS
ops_edit $netmetadata DEFAULT nova_metadata_ip $CTL_MGNT_IP
ops_edit $netmetadata DEFAULT nova_metadata_port 8775
ops_edit $netmetadata DEFAULT metadata_proxy_shared_secret $METADATA_SECRET
ops_edit $netmetadata DEFAULT verbose True

ops_del $netmetadata DEFAULT admin_tenant_name
ops_del $netmetadata DEFAULT admin_user
ops_del $netmetadata DEFAULT admin_password 


echocolor "Create a symbolic link"
sleep 3
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

echocolor "Setup db"
sleep 3
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
  
### CONFIG NOVA FOR OVS
nova_ctl=/etc/nova/nova.conf
test -f $nova_ctl.orig1 || cp $nova_ctl $nova_ctl.orig1
ops_edit $nova_ctl DEFAULT linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver

## Setup IP for br-eth1
# yum install -y bridge-utils 

# nmcli c add type bridge autoconnect yes con-name br-eth1 ifname br-eth1
# nmcli c modify br-eth1 ipv4.addresses 172.16.69.40/24 ipv4.method manual
# nmcli c modify br-eth1 ipv4.gateway 172.16.69.1
# nmcli c modify br-eth1 ipv4.dns 8.8.8.8
# nmcli c delete eth1 && nmcli c add type bridge-slave autoconnect yes con-name eth1 ifname eth1 master br-eth1


echocolor "Restarting NEUTRON service"
sleep 3
systemctl start neutron-server
systemctl enable neutron-server 
systemctl start openvswitch 
systemctl enable openvswitch
systemctl restart neutron-openvswitch-agent 
systemctl restart openstack-nova-api


for service in dhcp-agent l3-agent metadata-agent openvswitch-agent; do
systemctl start neutron-$service
systemctl enable neutron-$service
done 

### Setup IP for bridge card
echocolor "Setup IP for bridge card"
sleep 5

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
IPADDR=$CTL_EXT_IP
PREFIX=$PREFIX_NETMASK_EXT
GATEWAY=$GATEWAY_IP_EXT
DNS1=$DNS_SERVER
ONBOOT="yes"
TYPE="OVSBridge"
DEVICETYPE="ovs"
EOF

echocolor "Add bridge"
sleep 3
ovs-vsctl add-br br-int 
ovs-vsctl add-br br-eth1 
ovs-vsctl add-port br-eth1 eth1 

echocolor "Finished install NEUTRON on CONTROLLER"
init 6 

