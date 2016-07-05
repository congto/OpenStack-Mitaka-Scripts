#!/bin/bash -ex
#

source config.cfg
source functions.sh
echocolor "Installing CRUDINI"
sleep 3
yum -y install crudini


###########################################################
echocolor "Install and config NTP"
sleep 3
yum -y install chrony
ntpfile=/etc/chrony.conf
cp $ntpfile $ntpfile.orig

sed -i "s/server 0.debian.pool.ntp.org offline minpoll 8/ \
server $CTL_MGNT_IP iburst/g" $ntpfile


sed -i 's/server 1.centos.pool.ntp.org iburst/ \
# server 1.centos.pool.ntp.org iburst/g' $ntpfile

sed -i 's/server 2.centos.pool.ntp.org iburst/ \
# server 2.centos.pool.ntp.org iburst/g' $ntpfile

sed -i 's/server 3.centos.pool.ntp.org iburst/ \
# server 3.centos.pool.ntp.org iburst/g' $ntpfile

echocolor "Start the NTP service"
sleep 3
systemctl enable chronyd.service
systemctl start chronyd.service

echocolor "Check service NTP"
sleep 3
chronyc sources

sleep 5
echocolor "Installl package for NOVA"

yum -y install openstack-nova-compute
echocolor "Install & Configuring in nova.conf"
sleep 5
#Backup nova.conf
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

echocolor "Restart and start nova-compute when reboot server"
sleep 5
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

# Remove default nova db
rm /var/lib/nova/nova.sqlite

echocolor "Install neutron-linuxbridge-agent (neutron) on COMPUTE NODE"
sleep 5
yum -y install openstack-neutron-linuxbridge ebtables ipset

echocolor "Config file neutron.conf"
neutron_com=/etc/neutron/neutron.conf
test -f $neutron_com.orig || cp $neutron_com $neutron_com.orig

## [DEFAULT] section
ops_edit $neutron_com DEFAULT core_plugin ml2
ops_edit $neutron_com DEFAULT rpc_backend rabbit
ops_edit $neutron_com DEFAULT auth_strategy keystone

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

## [oslo_concurrency] section
ops_edit $neutron_com oslo_concurrency lock_path /var/lib/neutron/tmp

echocolor "Configuring linuxbridge_agent"
sleep 5
########
lbfile_com=/etc/neutron/plugins/ml2/linuxbridge_agent.ini
test -f $lbfile_com.orig || cp $lbfile_com $lbfile_com.orig

# [linux_bridge] section
ops_edit $lbfile_com linux_bridge physical_interface_mappings provider:eth1


## [securitygroup] section
ops_edit $lbfile_com securitygroup enable_security_group True
ops_edit $lbfile_com securitygroup firewall_driver \
    neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

# [vxlan] section
ops_edit $lbfile_com vxlan enable_vxlan True
ops_edit $lbfile_com vxlan local_ip $COM1_MGNT_IP
ops_edit $lbfile_com vxlan l2_population True

echocolor "Reset service nova-compute,linuxbridge-agent"
sleep 5
systemctl restart openstack-nova-compute.service

systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service
