#!/bin/bash -ex
#
source config.cfg
source functions.sh

echocolor "Installing CRUDINI"
sleep 3
yum -y install crudini


###########################################################
echocolor "Install and config NTP"
sleep 3
yum -y install chrony
ntpfile=/etc/chrony.conf
cp $ntpfile $ntpfile.orig

sed -i 's/server 0.centos.pool.ntp.org iburst/ \
server 1.vn.pool.ntp.org iburst \
server 0.asia.pool.ntp.org iburst \
server 3.asia.pool.ntp.org iburst/g' $ntpfile

sed -i 's/server 1.centos.pool.ntp.org iburst/ \
# server 1.centos.pool.ntp.org iburst/g' $ntpfile

sed -i 's/server 2.centos.pool.ntp.org iburst/ \
# server 2.centos.pool.ntp.org iburst/g' $ntpfile

sed -i 's/server 3.centos.pool.ntp.org iburst/ \
# server 3.centos.pool.ntp.org iburst/g' $ntpfile

sed -i 's/#allow 192.168\/16/allow 172.16.69.0\/24/g' $ntpfile

echocolor "Start the NTP service"
sleep 3
systemctl enable chronyd.service
systemctl start chronyd.service

echocolor "Check service NTP"
sleep 3
chronyc sources

###########################################################
echocolor "Install and Config RabbitMQ"
sleep 3
yum -y install rabbitmq-server

echocolor "Starting rabbitmq-server"
sleep 3
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service

rabbitmqctl add_user openstack $RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

###########################################################
echocolor "Install MYSQL"
sleep 3
yum -y install mariadb mariadb-server python2-PyMySQL

echocolor "Configuring MYSQL"
sleep 5
touch /etc/my.cnf.d/openstack.cnf
cat << EOF > /etc/my.cnf.d/openstack.cnf
[mysqld]
bind-address = 0.0.0.0

default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
character-set-server = utf8

EOF

echocolor "Starting MYSQL"
sleep 5
systemctl start mariadb.service

cat > /root/config.sql <<EOF
delete from mysql.user where user='';
update mysql.user set password=password("$MYSQL_PASS");
flush privileges;
EOF

mysql -u root -e'source /root/config.sql'
rm -rf /root/config.sql

echocolor "Enable service mariadb when reboot server"
sleep 3
systemctl enable mariadb.service

###########################################################
echocolor "Installing memcached"
sleep 3
yum -y install memcached python-memcached

echocolor "Enable service mariadb when reboot server"
sleep 3
systemctl enable memcached.service
systemctl start memcached.service
