## Ghi chep cai dat OpenStack tren CentOS7

# Thuc hien tren Controller

-  Setup ip cho eth0
```sh
nmcli c modify eth0 ipv4.addresses 10.10.10.43/24
nmcli c modify eth0 ipv4.method manual
# nmcli c down eth0; nmcli c up eth0
```

-  Setup ip cho eth0
```sh
nmcli c modify eth1 ipv4.addresses 172.16.69.43/24
nmcli c modify eth1 ipv4.gateway 172.16.69.1
nmcli c modify eth1 ipv4.dns 8.8.8.8
nmcli c modify eth1 ipv4.method manual
# nmcli c down eth1; nmcli c up eth1
```

# Cau hinh hostname 
```sh
echocolor "Configuring for file /etc/hosts"
sleep 3
iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1       localhost $HOST_CTL
$CTL_MGNT_IP    $HOST_CTL
$COM1_MGNT_IP   $HOST_COM1
$CIN_MGNT_IP    $HOST_CIN
EOF
````




























############################################
# Cai dat OpenStack Mitaka tren CentOS7.x

## Setup IP, hostname, sua file /etc/hosts
- Thiet lap IP

nmcli c modify eth0 ipv4.addresses 10.10.10.43/24
nmcli c modify eth0 ipv4.method manual
# nmcli c down eth0; nmcli c up eth0

# nmcli d show eth1 

nmcli c modify eth1 ipv4.addresses 172.16.69.43/24
nmcli c modify eth1 ipv4.gateway 172.16.69.1
nmcli c modify eth1 ipv4.dns 8.8.8.8
nmcli c modify eth1 ipv4.method manual
# nmcli c down eth1; nmcli c up eth1

# nmcli d show eth1 

systemctl restart network


- Cau hinh hostname
hostnamectl set-hostname compute2

- Cai hinh /etc/hosts


## Cai dat ntp
yum -y install chrony

- Mo file  

vi /etc/chrony.conf

- Comment cac dong duoi 
# server 0.centos.pool.ntp.org iburst
# server 1.centos.pool.ntp.org iburst
# server 2.centos.pool.ntp.org iburst
# server 3.centos.pool.ntp.org iburst

- Them dong duoi
server 10.10.10.40 iburst

- Khoi dong dich vu NTP
systemctl enable chronyd.service
systemctl start chronyd.service

- Kiem tra dich vu NTP xem da hoa dong hay chua
chronyc sources

- Ket qua nhu sau:
[root@localhost network-scripts]# chronyc sources
210 Number of sources = 1
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* 10.10.10.40                    2   6    17     3  +3249ns[ +148us] +/-  200ms



## Khai bao goi cai dat cho OpenStack Mitaka

yum -y install  centos-release-openstack-mitaka

yum -y install https://rdoproject.org/repos/rdo-release.rpm

yum -y upgrade

yum -y install python-openstackclient

yum -y install openstack-selinux


####################################################################################
# Cai dat NOVA tren NODE COMPUTE (Su dung CentOS7)


echo 'net.ipv4.conf.default.rp_filter=0' >> /etc/sysctl.conf 
echo 'net.ipv4.conf.all.rp_filter=0' >> /etc/sysctl.conf 


## Cai dat NOVA tren CentOS7
yum -y install openstack-nova-compute

- Sao luu file 
cp /etc/nova/nova.conf /etc/nova/nova.conf.orig

- Khai bao them vao file /etc/nova/nova.conf
[DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone
my_ip =10.10.10.43
use_neutron = True
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
vif_plugging_is_fatal = True
vif_plugging_timeout = 300

[oslo_messaging_rabbit]
rabbit_host = 10.10.10.40
rabbit_userid = openstack
rabbit_password = Welcome123


[keystone_authtoken]
auth_uri = http://10.10.10.40:5000
auth_url = http://10.10.10.40:35357
memcached_servers = 10.10.10.40:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = Welcome123


[vnc]
enabled = True
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = $my_ip
novncproxy_base_url = http://10.10.10.40:6080/vnc_auto.html

[glance]
api_servers = http://10.10.10.40:9292

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

[neutron]
url = http://10.10.10.40:9696
auth_url = http://10.10.10.40:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = Welcome123

- Khoi dong lai dich vu nova-compute
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

####################################################################################
# Cai dat NEUTRON tren NODE COMPUTE (Su dung CentOS7)
## Cai dat NEUTRON 
yum -y install openstack-neutron-openvswitch ebtables ipset
 yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch

- Sao chep file /etc/neutron/neutron.conf
cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig
cat /etc/neutron/neutron.conf.orig | egrep -v '^$|^#' > /etc/neutron/neutron.conf

- Khai bao cac section nhu sau

[DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone


[oslo_messaging_rabbit]
rabbit_host = 10.10.10.40
rabbit_userid = openstack
rabbit_password = Welcome123


[keystone_authtoken]
auth_uri = http://10.10.10.40:5000
auth_url = http://10.10.10.40:35357
memcached_servers = 10.10.10.40:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = Welcome123


[oslo_concurrency]
lock_path = /var/lib/neutron/tmp


- Sao luu file /etc/neutron/plugins/ml2/ml2_conf.ini
cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig
cat /etc/neutron/plugins/ml2/ml2_conf.ini.orig | egrep -v '^#|^$'  > /etc/neutron/plugins/ml2/ml2_conf.ini

- Cau hinh file etc/neutron/plugins/ml2/ml2_conf.ini nhu sau

[DEFAULT]

[ml2]
type_drivers = flat,vlan,gre,vxlan
tenant_network_types = gre
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security


[ml2_type_flat]
[ml2_type_geneve]
[ml2_type_gre]
tunnel_id_ranges = 300:400

[ml2_type_vlan]
[ml2_type_vxlan]

[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_ipset = True


- Cau hinh lien ket
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini 

- Sao luu openvswitch-agent
cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig
cat /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig | egrep -v '^#|^$' > /etc/neutron/plugins/ml2/openvswitch_agent.ini


- Cau hinh openvswitch-agent
[DEFAULT]

[ml2]
type_drivers = flat,vlan,gre,vxlan
tenant_network_types = gre
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security


[ml2_type_flat]
[ml2_type_geneve]
[ml2_type_gre]
tunnel_id_ranges = 300:400

[ml2_type_vlan]
[ml2_type_vxlan]

[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_ipset = True

- Cau hinh br-int
ovs-vsctl add-br br-int 

- Khoi dong lai neutron-openvswitch agent
systemctl enable neutron-openvswitch-agent.service
systemctl start neutron-openvswitch-agent.service

