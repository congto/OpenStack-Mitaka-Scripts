#!/bin/bash -ex

source config.cfg
source functions.sh

echocolor "Create the external network"
sleep 3

neutron net-create ext-net --router:external True \
    --provider:physical_network external --provider:network_type flat
    
echocolor "Create a subnet on the external network:"
sleep 3
neutron subnet-create ext-net --name ext-subnet --allocation-pool \
    start=172.16.69.30,end=172.16.69.39 --disable-dhcp \
    --gateway 172.16.69.1 172.16.69.0/24
    
tenant_id=`openstack project show demo | egrep -w id | awk '{print $4}'`

echocolor "Create the project network"
sleep 3
neutron net-create demo-net --tenant-id $tenant_id \
    --provider:network_type gre
    

echocolor "Create a subnet on the project network"
sleep 3
neutron subnet-create demo-net --name demo-subnet --gateway 192.168.10.1 \
    192.168.10.0/24
    
echocolor"Create a project router"
sleep 3
neutron router-create demo-router

echocolor "Add the project subnet as an interface on the router"
sleep 3
neutron router-interface-add demo-router demo-subnet

echocolor "Add a gateway to the external network on the router"
sleep 3
neutron router-gateway-set demo-router ext-net
