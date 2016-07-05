#!/bin/bash -ex

source config.cfg
source functions.sh
#!/bin/bash -ex

source config.cfg
source functions.sh

# Setup firewall
echocolor "Setup firewall"
sleep 3
systemctl stop firewalld 
systemctl disable firewalld 
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

echocolor "Setup IP  eth0"
sleep 3
nmcli c modify eth0 ipv4.addresses $COM1_MGNT_IP/24
nmcli c modify eth0 ipv4.method manual

echocolor "Setup IP  eth1"
sleep 3
nmcli c modify eth1 ipv4.addresses $COM1_EXT_IP/24
nmcli c modify eth1 ipv4.gateway $GATEWAY_IP_EXT
nmcli c modify eth1 ipv4.dns $DNS_SERVER
nmcli c modify eth1 ipv4.method manual

echocolor "Configuring hostname in CONTROLLER node"
sleep 3
hostnamectl set-hostname $HOST_COM1

echocolor "Configuring for file /etc/hosts"
sleep 3
iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1       localhost $HOST_COM1
$CTL_MGNT_IP    $HOST_CTL
$COM1_MGNT_IP   $HOST_COM1
$CIN_MGNT_IP    $HOST_CIN
EOF

echocolor "Enable the OpenStack Mitaka repository"
sleep 3
# CENTOS
yum -y install centos-release-openstack-mitaka
# RHEL
# yum -y install https://rdoproject.org/repos/rdo-release.rpm


echocolor "Upgrade the packages for server"
sleep 3
yum -y upgrade

echocolor "Install python client"
sleep 3
yum -y install python-openstackclient
yum -y install openstack-selinux

echocolor "Install utility"
sleep 3
yum -y install wget 

echocolor "Sepup tool"
sed -i 's/notify_only=1/notify_only=0/g' \
    /etc/yum/pluginconf.d/search-disabled-repos.conf


echocolor "Reboot Server"
sleep 3
init 6
#




