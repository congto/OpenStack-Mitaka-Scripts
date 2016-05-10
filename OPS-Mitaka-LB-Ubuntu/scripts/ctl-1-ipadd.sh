#!/bin/bash -ex

source config.cfg
source functions.sh

ifaces=/etc/network/interfaces
test -f $ifaces.orig || cp $ifaces $ifaces.orig
rm $ifaces
touch $ifaces
cat << EOF >> $ifaces
#Assign IP for Controller node

# LOOPBACK NET
auto lo
iface lo inet loopback

# MGNT NETWORK
auto eth0
iface eth0 inet static
address $CTL_MGNT_IP
netmask $NETMASK_ADD_MGNT

# EXT NETWORK
auto eth1
iface eth1 inet static
address $CTL_EXT_IP
netmask $NETMASK_ADD_EXT
gateway $GATEWAY_IP_EXT
dns-nameservers 8.8.8.8
EOF

echocolor "Configuring hostname in CONTROLLER node"
sleep 3
echo "$HOST_CTL" > /etc/hostname
hostname -F /etc/hostname

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

echocolor "Enable the OpenStack Mitaka repository"
apt-get install software-properties-common -y
add-apt-repository cloud-archive:mitaka -y

sleep 5
echocolor "Upgrade the packages for server"
apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade

sleep 5
echocolor "Reboot Server"

#sleep 5
init 6
#
