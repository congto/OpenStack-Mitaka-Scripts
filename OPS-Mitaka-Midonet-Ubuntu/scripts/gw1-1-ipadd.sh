#!/bin/bash -ex

source config.cfg
source functions.sh

echocolor "Enable the OpenStack Mitaka repository"
sleep 5

cat << EOF >> /etc/apt/sources.list
# Ubuntu Main Archive
deb http://archive.ubuntu.com/ubuntu/ trusty main
# deb http://security.ubuntu.com/ubuntu trusty-updates main
deb http://security.ubuntu.com/ubuntu trusty-security main

# Ubuntu Universe Archive
deb http://archive.ubuntu.com/ubuntu/ trusty universe
deb http://security.ubuntu.com/ubuntu trusty-updates universe
# deb http://security.ubuntu.com/ubuntu trusty-security universe
EOF

cat << EOF >> /etc/apt/sources.list.d/cloudarchive-mitaka.list 

# Ubuntu Cloud Archive
deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/mitaka main
EOF

apt-get -y update
apt-get -y install ubuntu-cloud-keyring

cat << EOF >  /etc/apt/sources.list.d/datastax.list
# DataStax (Apache Cassandra)
deb http://debian.datastax.com/community 2.2 main
EOF

curl -L https://debian.datastax.com/debian/repo_key | apt-key add -

cat << EOF > /etc/apt/sources.list.d/openjdk-8.list
# OpenJDK 8
deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main
EOF

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x86F44E2A

cat << EOF > /etc/apt/sources.list.d/midonet.list
# MidoNet
deb http://builds.midonet.org/midonet-5.2 stable main

# MidoNet OpenStack Integration
deb http://builds.midonet.org/openstack-mitaka stable main

# MidoNet 3rd Party Tools and Libraries
deb http://builds.midonet.org/misc stable main
EOF


curl -L https://builds.midonet.org/midorepo.key | apt-key add -

sleep 5
echocolor "Upgrade the packages for server"
apt-get -y update && apt-get -y upgrade && apt-get -y dist-upgrade

echocolor "Configuring hostname for HOST_GW1 node"
sleep 3
echo "$HOST_GW1" > /etc/hostname
hostname -F /etc/hostname

iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1       localhost $HOST_GW1
$CTL_MGNT_IP    $HOST_CTL
$COM1_MGNT_IP   $HOST_COM1
$COM2_MGNT_IP   $HOST_COM2
$CIN_MGNT_IP    $HOST_CIN

$NSDB1_MGNT_IP  $HOST_NSDB1
$NSDB2_MGNT_IP  $HOST_NSDB2
$NSDB3_MGNT_IP  $HOST_NSDB3

$GW1_MGNT_IP    $HOST_GW1
$GW2_MGNT_IP    $HOST_GW2
EOF

sleep 3
echocolor "Config network for Compute1 node"
ifaces=/etc/network/interfaces
test -f $ifaces.orig || cp $ifaces $ifaces.orig
rm $ifaces
touch $ifaces
cat << EOF >> $ifaces
#Dat IP cho $HOST_NSDB1 node

# LOOPBACK NET
auto lo
iface lo inet loopback

# DATA NETWORK
# auto eth0
# iface eth0 inet static
# address $GW1_DATA_IP
# netmask $NETMASK_DATA


# MGNT NETWORK
auto eth1
iface eth1 inet static
address $GW1_MGNT_IP
netmask $NETMASK_MNGT
# gateway $GATEWAY_MNGT
# dns-nameservers 8.8.8.8

# MGNT NETWORK
auto eth2
iface eth2 inet static
address $GW1_EXT_IP
netmask $NETMASK_UPLINK1
gateway $GATEWAY_UPLINK1
dns-nameservers 8.8.8.8




EOF

sleep 5
echocolor "Rebooting machine ..."
init 6
#




