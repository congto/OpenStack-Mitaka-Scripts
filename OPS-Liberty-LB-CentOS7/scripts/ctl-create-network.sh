#!/bin/bash -ex

source config.cfg
source functions.sh

echocolor "Create the external network"
sleep 3

neutron net-create ext-net --router:external True \
    --provider:physical_network provider --provider:network_type flat
    
echocolor "Create a subnet on the external network:"
sleep 3
neutron subnet-create ext-net --name ext-subnet --allocation-pool \
    start=172.16.69.30,end=172.16.69.39 --disable-dhcp \
    --dns-nameserver 8.8.4.4 --gateway 172.16.69.1 172.16.69.0/24
    
tenant_id=`openstack project show admin | egrep -w id | awk '{print $4}'`

echocolor "Create the project network"
sleep 3
neutron net-create selfservice
    

echocolor "Create a subnet on the project network"
sleep 3
neutron subnet-create --name selfservice \
  --dns-nameserver 8.8.4.4 --gateway 192.168.10.1 \
  selfservice 192.168.10.0/24
    
echocolor "Create a project router"
sleep 3
neutron router-create admin-router

echocolor "Add the project subnet as an interface on the router"
sleep 3
 neutron router-interface-add admin-router selfservice

echocolor "Add a gateway to the external network on the router"
sleep 3
neutron router-gateway-set admin-router ext-net

echocolor "Allow SSH, ICMP protocol"
openstack security group rule create default --proto icmp
openstack security group rule create default --proto tcp --dst-port 22

echocolor "List network namespaces and ports on the router"
ip netns
neutron router-port-list admin-router
