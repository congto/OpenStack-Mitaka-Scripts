#!/bin/bash -ex

source config.cfg
source functions.sh

openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

echocolor "Create the provider network - VLAN"
sleep 3

neutron net-create provider_VLAN --shared \
  --provider:physical_network provider --provider:network_type vlan \
  --provider:segmentation_id 101

 neutron subnet-create provider_VLAN 192.168.101.0/24 \
  	--name provider_subnet_VLAN101 \
  	--gateway 192.168.101.1 \
  	--dns-nameserver 8.8.8.8 \
  	--allocation-pool start=192.168.101.20,end=192.168.101.60

echocolor "Create VM"
nova boot --flavor m1.tiny --image cirros VM1