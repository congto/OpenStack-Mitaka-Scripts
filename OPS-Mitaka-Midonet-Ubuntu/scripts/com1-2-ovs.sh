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
# echo "libguestfs-tools libguestfs/update-appliance boolean true" \
#    | debconf-set-selections
# apt-get -y install libguestfs-tools sysfsutils guestfsd python-guestfs

# Fix KVM bug when injecting password
# update-guestfs-appliance
# chmod 0644 /boot/vmlinuz*
# usermod -a -G kvm root


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
#ops_edit $nova_com DEFAULT \
#	linuxnet_interface_driver nova.network.linux_net.LinuxOVSInterfaceDriver
    
# ops_edit $nova_com DEFAULT network_api_class nova.network.neutronv2.api.API
# ops_edit $nova_com DEFAULT security_group_api neutron


# ops_edit $nova_com DEFAULT enable_instance_password True

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


cat << EOF >> /etc/libvirt/qemu.conf
user = "root"
group = "root"

cgroup_device_acl = [
    "/dev/null", "/dev/full", "/dev/zero",
    "/dev/random", "/dev/urandom",
    "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
    "/dev/rtc","/dev/hpet", "/dev/vfio/vfio",
    "/dev/net/tun"
]
EOF

echocolor "libvirt-bin COMPUTE NODE"
sleep 5
service libvirt-bin restart

