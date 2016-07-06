#!/bin/bash -ex

source config.cfg
source functions.sh

echocolor "Create the external network"
sleep 3


neutron net-create --shared --provider:physical_network provider \
    --provider:network_type flat provider

neutron subnet-create --name provider \
  --allocation-pool start=172.16.69.100,end=172.16.69.109 \
  --dns-nameserver 8.8.4.4 --gateway 172.16.69.1 \
  provider 172.16.69.0/24
  
neutron net-create selfservice

neutron subnet-create --name selfservice \
    --dns-nameserver 8.8.4.4 --gateway 172.16.1.1 \
    selfservice 172.16.1.0/24
    
neutron net-update provider --router:external

neutron router-create router

neutron router-interface-add router selfservice

neutron router-gateway-set router provider

echocolor "Allow SSH, ICMP protocol"
openstack security group rule create default --proto icmp
openstack security group rule create default --proto tcp --dst-port 22
