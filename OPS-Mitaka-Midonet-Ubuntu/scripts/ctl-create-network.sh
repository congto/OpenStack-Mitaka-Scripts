#!/bin/bash -ex

source config.cfg
source functions.sh

openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

echocolor "Create the external network"
sleep 3


neutron net-create --shared --provider:physical_network external \
--provider:network_type flat ext-net
  
neutron subnet-create --name sub-ext-net \
--allocation-pool start=172.16.69.180,end=172.16.69.189 \
--dns-nameserver 8.8.4.4 --gateway 172.16.69.1 \
ext-net 172.16.69.0/24

# Tao VM gan vao provider network
ext_net_id=`openstack network list | egrep -w ext-net | awk '{print $2}'`

openstack server create --flavor m1.tiny --image cirros \
  --nic net-id=$ext_net_id --security-group default \
  provider-instance

#  Tao Selfservice network
    
tenant_id=`openstack project show admin | egrep -w id | awk '{print $4}'`

echocolor "Create the project network"
sleep 3
neutron net-create private-net --tenant-id $tenant_id \
    --provider:network_type gre
    

echocolor "Create a subnet on the project network"
sleep 3
neutron subnet-create private-net --name private-subnet \
    --dns-nameserver 8.8.8.8 --gateway 192.168.10.1 192.168.10.0/24

neutron net-update ext-net --router:external
neutron router-create admin-router

neutron router-interface-add admin-router private-subnet
neutron router-gateway-set admin-router ext-net


# Gan may ao vao selfservice network 
private_net_id=`openstack network list | egrep -w private-net | awk '{print $2}'`
openstack server create --flavor m1.tiny --image cirros \
  --nic net-id=$private_net_id --security-group default \
  Selfservice-instance

# Floating IP 
openstack ip floating create ext-net

openstack ip floating add dia_chi_ip_floating selfservice-instance
openstack ip floating add 172.16.69.183 Selfservice-instance
######################
  
    
echocolor "Create a project router"
sleep 3
neutron router-create admin-router

echocolor "Add the project subnet as an interface on the router"
sleep 3
neutron router-interface-add admin-router private-subnet

echocolor "Add a gateway to the external network on the router"
sleep 3
neutron router-gateway-set admin-router ext-net

echocolor "Allow SSH, ICMP protocol"
openstack security group rule create default --proto icmp
openstack security group rule create default --proto tcp --dst-port 22



