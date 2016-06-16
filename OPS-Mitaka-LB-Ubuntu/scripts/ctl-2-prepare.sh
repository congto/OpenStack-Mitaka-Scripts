#!/bin/bash -ex
#
source config.cfg
source functions.sh

echocolor "Installing CRUDINI"
sleep 3

apt-get -y install python-pip
pip install \
    https://pypi.python.org/packages/source/c/crudini/crudini-0.7.tar.gz

echocolor "Install python client"
apt-get -y install python-openstackclient
sleep 5

echocolor "Install and config NTP"
sleep 3


apt-get -y install chrony
ntpfile=/etc/chrony/chrony.conf
cp $ntpfile $ntpfile.orig

sed -i 's/server 0.debian.pool.ntp.org offline minpoll 8/ \
server 1.vn.pool.ntp.org iburst \
server 0.asia.pool.ntp.org iburst \
server 3.asia.pool.ntp.org iburst/g' $ntpfile

sed -i 's/server 1.debian.pool.ntp.org offline minpoll 8/ \
# server 1.debian.pool.ntp.org offline minpoll 8/g' $ntpfile

sed -i 's/server 2.debian.pool.ntp.org offline minpoll 8/ \
# server 2.debian.pool.ntp.org offline minpoll 8/g' $ntpfile

sed -i 's/server 3.debian.pool.ntp.org offline minpoll 8/ \
# server 3.debian.pool.ntp.org offline minpoll 8/g' $ntpfile

##############################################
echocolor "Install and Config RabbitMQ"
sleep 3

apt-get install rabbitmq-server -y
rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
# rabbitmqctl change_password guest $RABBIT_PASS
sleep 3

service rabbitmq-server restart
echocolor "Finish setup pre-install package !!!"

echocolor "Install MYSQL"
sleep 3

echo mysql-server mysql-server/root_password password \
$MYSQL_PASS | debconf-set-selections
echo mysql-server mysql-server/root_password_again password \
$MYSQL_PASS | debconf-set-selections
apt-get -y install mariadb-server python-mysqldb curl

echocolor "Configuring MYSQL"
sleep 5

touch /etc/mysql/conf.d/mysqld_openstack.cnf
cat << EOF > /etc/mysql/conf.d/mysqld_openstack.cnf

[mysqld]
bind-address = 0.0.0.0

default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8

EOF

sleep 5
echocolor "Restarting MYSQL"
service mysql restart
