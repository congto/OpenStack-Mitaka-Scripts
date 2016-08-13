#!/bin/bash -ex

source config.cfg
source functions.sh

# Install ZooKeeper packages
apt-get -y install openjdk-8-jre-headless
apt-get -y install zookeeper zookeeperd zkdump

# Configure ZooKeeper

cat << EOF >> /etc/zookeeper/conf/zoo.cfg
server.1=nsdb1:2888:3888
server.2=nsdb2:2888:3888
server.3=nsdb3:2888:3888
autopurge.snapRetainCount=10
autopurge.purgeInterval =12
EOF

# Node-specific Configuration on NSBD1
echo 2 > /var/lib/zookeeper/myid

# Restart ZooKeeper
service zookeeper restart

# Cassandra Installation
apt-get -y install dsc22

sed -i 's/Test Cluster/midonet/g' /etc/cassandra/cassandra.yaml
sed -i 's/127.0.0.1/172.16.69.191,172.16.69.192,172.16.69.193/g' /etc/cassandra/cassandra.yaml
sed -i 's/localhost/172.16.69.192/g' /etc/cassandra/cassandra.yaml

service cassandra stop
rm -rf /var/lib/cassandra/*
service cassandra start