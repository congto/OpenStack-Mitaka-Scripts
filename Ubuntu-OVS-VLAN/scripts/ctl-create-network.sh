#!/bin/bash -ex

source config.cfg
source functions.sh

echocolor "Tạo các rule cho security groups"
sleep 3
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default

echocolor "Tạo provider network theo kiểu VLAN"
# --provider:network_type vlan tham số "vlan" cần giống với file cấu hình ML2 trên controller
sleep 3

neutron net-create provider_VLAN --shared \
	--router:external True \
  	--provider:physical_network provider --provider:network_type vlan \
  	--provider:segmentation_id 101

 neutron subnet-create provider_VLAN 192.168.101.0/24 \
  	--name provider_subnet_VLAN101 \
  	--gateway 192.168.101.1 \
  	--dns-nameserver 8.8.8.8 \
  	--allocation-pool start=192.168.101.20,end=192.168.101.60

echocolor "Tao VM"
nova boot --flavor m1.tiny --image cirros VM1

echocolor "Tao private network su dung VXLAN"
sleep 3
neutron net-create private-net  --provider:network_type vxlan
neutron subnet-create private-net --name private-net-subnet --gateway 172.16.10.1 172.16.10.0/24