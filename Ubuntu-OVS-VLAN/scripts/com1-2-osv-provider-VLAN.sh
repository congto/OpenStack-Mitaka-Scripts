#!/bin/bash -ex
#

source config.cfg
source functions.sh

apt-get -y install python-pip
pip install \
    https://pypi.python.org/packages/source/c/crudini/crudini-0.7.tar.gz

#

cat << EOF >> /etc/sysctl.conf
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF

echocolor "Install python openstack client"
apt-get -y install python-openstackclient

echocolor "Install and config NTP"
sleep 3

apt-get -y install chrony
ntpfile=/etc/chrony/chrony.conf
cp $ntpfile $ntpfile.orig

sed -i "s/server 0.debian.pool.ntp.org offline minpoll 8/ \
server $CTL_MGNT_IP iburst/g" $ntpfile


sed -i 's/server 1.debian.pool.ntp.org offline minpoll 8/ \
# server 1.debian.pool.ntp.org offline minpoll 8/g' $ntpfile

sed -i 's/server 2.debian.pool.ntp.org offline minpoll 8/ \
# server 2.debian.pool.ntp.org offline minpoll 8/g' $ntpfile

sed -i 's/server 3.debian.pool.ntp.org offline minpoll 8/ \
# server 3.debian.pool.ntp.org offline minpoll 8/g' $ntpfile

sleep 5
echocolor "Installl package for NOVA"

apt-get -y install nova-compute

echocolor "Configuring in nova.conf"
sleep 5
########
#/* Backup nova.conf
nova_com=/etc/nova/nova.conf
test -f $nova_com.orig || cp $nova_com $nova_com.orig

## [DEFAULT] Section
ops_edit $nova_com DEFAULT rpc_backend rabbit
ops_edit $nova_com DEFAULT auth_strategy keystone
ops_edit $nova_com DEFAULT my_ip $COM1_MGNT_IP
ops_edit $nova_com DEFAULT use_neutron  True
ops_edit $nova_com DEFAULT \
    firewall_driver nova.virt.firewall.NoopFirewallDriver

## [oslo_messaging_rabbit] section
ops_edit $nova_com oslo_messaging_rabbit rabbit_host $CTL_MGNT_IP
ops_edit $nova_com oslo_messaging_rabbit rabbit_userid openstack
ops_edit $nova_com oslo_messaging_rabbit rabbit_password $RABBIT_PASS

## [keystone_authtoken] section
ops_edit $nova_com keystone_authtoken auth_uri http://$CTL_MGNT_IP:5000
ops_edit $nova_com keystone_authtoken auth_url http://$CTL_MGNT_IP:35357
ops_edit $nova_com keystone_authtoken memcached_servers $CTL_MGNT_IP:11211
ops_edit $nova_com keystone_authtoken auth_type password
ops_edit $nova_com keystone_authtoken project_domain_name default
ops_edit $nova_com keystone_authtoken user_domain_name default
ops_edit $nova_com keystone_authtoken project_name service
ops_edit $nova_com keystone_authtoken username nova
ops_edit $nova_com keystone_authtoken password $NOVA_PASS

## [vnc] section
ops_edit $nova_com vnc enabled True
ops_edit $nova_com vnc vncserver_listen 0.0.0.0
ops_edit $nova_com vnc vncserver_proxyclient_address \$my_ip
ops_edit $nova_com vnc vncserver_proxyclient_address \$my_ip
ops_edit $nova_com vnc \
    novncproxy_base_url http://$CTL_EXT_IP:6080/vnc_auto.html

## [glance] section
ops_edit $nova_com glance api_servers http://$CTL_MGNT_IP:9292

## [oslo_concurrency] section
ops_edit $nova_com oslo_concurrency lock_path /var/lib/nova/tmp

## [neutron] section
ops_edit $nova_com neutron url http://$CTL_MGNT_IP:9696
ops_edit $nova_com neutron auth_url http://$CTL_MGNT_IP:35357
ops_edit $nova_com neutron auth_type password
ops_edit $nova_com neutron project_domain_name default
ops_edit $nova_com neutron user_domain_name default
ops_edit $nova_com neutron region_name RegionOne
ops_edit $nova_com neutron project_name service
ops_edit $nova_com neutron username neutron
ops_edit $nova_com neutron password $NEUTRON_PASS

echocolor "Restart nova-compute"
sleep 5
service nova-compute restart

# Remove default nova db
rm /var/lib/nova/nova.sqlite

echocolor "Install openvswitch-agent (neutron) on COMPUTE NODE"
sleep 5

apt-get -y install  neutron-plugin-openvswitch-agent neutron-common neutron-plugin-ml2 ipset

echocolor "Config file neutron.conf"
neutron_com=/etc/neutron/neutron.conf
test -f $neutron_com.orig || cp $neutron_com $neutron_com.orig

## [DEFAULT] section
ops_edit $neutron_com DEFAULT core_plugin ml2
ops_edit $neutron_com DEFAULT rpc_backend rabbit
ops_edit $neutron_com DEFAULT auth_strategy keystone
ops_edit $neutron_com DEFAULT service_plugins router

## [keystone_authtoken] section
ops_edit $neutron_com keystone_authtoken auth_uri http://$CTL_MGNT_IP:5000
ops_edit $neutron_com keystone_authtoken auth_url http://$CTL_MGNT_IP:35357
ops_edit $neutron_com keystone_authtoken memcached_servers $CTL_MGNT_IP:11211
ops_edit $neutron_com keystone_authtoken auth_type password
ops_edit $neutron_com keystone_authtoken project_domain_name default
ops_edit $neutron_com keystone_authtoken user_domain_name default
ops_edit $neutron_com keystone_authtoken project_name service
ops_edit $neutron_com keystone_authtoken username neutron
ops_edit $neutron_com keystone_authtoken password $NEUTRON_PASS


## [database] section
ops_del $neutron_com database connection

## [oslo_messaging_rabbit] section
ops_edit $neutron_com oslo_messaging_rabbit rabbit_host $CTL_MGNT_IP
ops_edit $neutron_com oslo_messaging_rabbit rabbit_userid openstack
ops_edit $neutron_com oslo_messaging_rabbit rabbit_password $RABBIT_PASS

echocolor "Configuring openvswitch_agent"
sleep 5
ovsfile=/etc/neutron/plugins/ml2/openvswitch_agent.ini
test -f $ovsfile.orig || cp $ovsfile $ovsfile.orig

## [agent] section
ops_edit $ovsfile agent tunnel_types vxlan,gre
ops_edit $ovsfile agent l2_population True


## [ovs] section
ops_edit $ovsfile ovs bridge_mappings provider:br-vlan
ops_edit $ovsfile ovs local_ip $COM1_DATA_VM_IP

# [securitygroup] section
ops_edit $ovsfile securitygroup firewall_driver neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
ops_edit $ovsfile securitygroup enable_ipset True
ops_edit $ovsfile securitygroup enable_security_group True

echocolor "Reset service nova-compute,openvswitch_agent"
sleep 5
service neutron-openvswitch-agent restart

echocolor "Config IP address for br-VLAN"
ifaces=/etc/network/interfaces
test -f $ifaces.orig1 || cp $ifaces $ifaces.orig1
rm $ifaces
cat << EOF > $ifaces
# The loopback network interface
auto lo
iface lo inet loopback

# IP MGNT (for internet)
auto eth0
iface eth0 inet static
address $COM1_DATA_VM_IP
netmask $NETMASK_ADD_DATA_VM


# IP EXTERNAL (for internet install package)
auto eth1
iface eth1 inet static
address $COM1_EXT_IP
netmask $NETMASK_ADD_EXT
gateway $GATEWAY_IP_EXT
dns-nameservers 8.8.8.8

# VLAN for VM (for internet)
auto eth2
iface eth2 inet manual
   up ifconfig \$IFACE 0.0.0.0 up
   up ip link set \$IFACE promisc on
   down ip link set \$IFACE promisc off
   down ifconfig \$IFACE down
EOF

echocolor "Config br-int and br-ex for OpenvSwitch"
sleep 5
# ovs-vsctl add-br br-int
ovs-vsctl add-br br-vlan
ovs-vsctl add-port br-vlan eth2

echocolor "Finished install NEUTRON on CONTROLLER"
sleep 5
echocolor "Reboot SERVER"
init 6
