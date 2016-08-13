#!/bin/bash -ex

source config.cfg
source functions.sh

#  MidoNet Cluster Installation

apt-get -y install midonet-cluster

cp /etc/midonet/midonet.conf /etc/midonet/midonet.conf.orig

sed -i 's/127.0.0.1:2181/nsdb1:2181,nsdb2:2181,nsdb3:2181/g' /etc/midonet/midonet.conf

cat << EOF | mn-conf set -t default
zookeeper {
    zookeeper_hosts = "nsdb1:2181,nsdb2:2181,nsdb3:2181"
}

cassandra {
    servers = "172.16.69.191,172.16.69.192,172.16.69.193"
}
EOF

 cat << EOF | mn-conf set -t default
cluster.auth {
    provider_class = "org.midonet.cluster.auth.keystone.KeystoneService"
    admin_role = "admin"
    keystone.tenant_name = "admin"
    keystone.admin_token = "Welcome123"
    keystone.host = 172.16.69.190
    keystone.port = 35357
}
EOF