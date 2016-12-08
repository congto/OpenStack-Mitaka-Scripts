#!/bin/bash -ex

source config.cfg
source functions.sh

echocolor "Enable the OpenStack Mitaka repository"
sleep 5
apt-get install software-properties-common -y
add-apt-repository cloud-archive:mitaka -y

sleep 5
echocolor "Upgrade the packages for server"
apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade

echocolor "Configuring hostname for COMPUTE1 node"
sleep 3
echo "$HOST_COM1" > /etc/hostname
hostname -F /etc/hostname

iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1       localhost $HOST_COM1
$CTL_MGNT_IP    $HOST_CTL
$COM1_MGNT_IP   $HOST_COM1
$COM2_MGNT_IP   $HOST_COM2
$CIN_MGNT_IP    $HOST_CIN
EOF

sleep 3
echocolor "Config network for Compute1 node"
ifaces=/etc/network/interfaces
test -f $ifaces.orig || cp $ifaces $ifaces.orig
rm $ifaces
touch $ifaces
cat << EOF >> $ifaces
#Dat IP cho $COM1_MGNT_IP node

# LOOPBACK NET
auto lo
iface lo inet loopback

# MGNT NETWORK
auto eth0
iface eth0 inet static
address $COM1_MGNT_IP
netmask $NETMASK_ADD_MGNT


# EXT NETWORK
auto eth1
iface eth1 inet static
address $COM1_EXT_IP
netmask $NETMASK_ADD_EXT
gateway $GATEWAY_IP_EXT
dns-nameservers 8.8.8.8

EOF

sleep 5
echocolor "Rebooting machine ..."
init 6
#




