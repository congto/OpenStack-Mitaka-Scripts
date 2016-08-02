#!/bin/bash -ex

source config.cfg
source functions.sh

openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

echocolor "Create the external network"
sleep 3


neutron net-create --shared --provider:physical_network external \
--provider:network_type flat ext-net
  
neutron subnet-create --name sub-provider \
--allocation-pool start=172.16.69.180,end=172.16.69.189 \
--dns-nameserver 8.8.4.4 --gateway 172.16.69.1 \
external 172.16.69.0/24
    
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



