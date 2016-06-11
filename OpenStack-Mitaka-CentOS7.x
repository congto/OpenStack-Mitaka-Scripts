# Cai dat OpenStack Mitaka tren CentOS7.x

## Setup IP, hostname, sua file /etc/hosts
- Thiet lap IP

- Cau hinh hostname

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
firewall_driver = nova.virt.firewall.NoopFirewallDriver

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

- Khoi dong lai dich vu nova-compute
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service