#!/bin/bash -ex
#
source config.cfg
source functions.sh

echocolor "Cai dat goi CRUDINI"
sleep 3

apt-get -y install python-pip
pip install \
	https://pypi.python.org/packages/source/c/crudini/crudini-0.7.tar.gz

echocolor "Install python client"
apt-get -y install python-openstackclient
sleep 5

echocolor "Install and config NTP"
sleep 3 
apt-get install ntp -y
cp /etc/ntp.conf /etc/ntp.conf.bka
rm /etc/ntp.conf
cat /etc/ntp.conf.bka | grep -v ^# | grep -v ^$ >> /etc/ntp.conf


## Config NTP in LIBERTY
sed -i 's/server ntp.ubuntu.com/ \
server 0.vn.pool.ntp.org iburst \
server 1.asia.pool.ntp.org iburst \
server 2.asia.pool.ntp.org iburst/g' /etc/ntp.conf

sed -i 's/restrict -4 default kod notrap nomodify nopeer noquery/ \
#restrict -4 default kod notrap nomodify nopeer noquery/g' /etc/ntp.conf

sed -i 's/restrict -6 default kod notrap nomodify nopeer noquery/ \
restrict -4 default kod notrap nomodify \
restrict -6 default kod notrap nomodify/g' /etc/ntp.conf

# sed -i 's/server/#server/' /etc/ntp.conf
# echocolor "server $LOCAL_IP" >> /etc/ntp.conf

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

echocolor "##### Install MYSQL #####"
sleep 3

echo mysql-server mysql-server/root_password password \
$MYSQL_PASS | debconf-set-selections
echo mysql-server mysql-server/root_password_again password \
$MYSQL_PASS | debconf-set-selections
apt-get -y install mariadb-server python-mysqldb curl 

echocolor "##### Configuring MYSQL #####"
sleep 3

echocolor "########## CONFIGURING FOR MYSQL ##########"
sleep 5
touch /etc/mysql/conf.d/mysqld_openstack.cnf
cat << EOF > /etc/mysql/conf.d/mysqld_openstack.cnf

[mysqld]
bind-address = 0.0.0.0

[mysqld]
default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8

EOF

sleep 5
echocolor "Restart MYSQL"
service mysql restart


