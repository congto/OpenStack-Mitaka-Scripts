### OpenStack Midonet

## Chuẩn bị

- Mô hình mạng

### Controller

```sh
- eth0: 10.10.10.190 255.255.255.0 
- eth1: 172.16.69.190 255.255.255.0 172.16.69.1
```

### Compute: 


## Cài đặt trên Controller

### Cấu hình IP 

```sh
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
address 10.10.10.190
netmask 255.255.255.0

# EXT NETWORK
auto eth1
iface eth1 inet static
address 172.16.69.190
netmask 255.255.255.0
gateway 172.16.69.1
dns-nameservers 8.8.8.8
EOF
```

### Cấu hình hostname
- File /etc/hostname

```sh
echo "controller" > /etc/hostname
hostname -F /etc/hostname
```

- File /etc/hosts

```sh
iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1      localhost controller
172.16.69.190  controller
172.16.69.191  compute1
172.16.69.192  nsdb1
172.16.69.193  nsdb2
172.16.69.194  nsdb3
172.16.69.195  gateway1
172.16.69.196  gateway2
EOF
```


###  Configure Ubuntu repositories

- Thêm vào file `/etc/apt/sources.list` với nội dung sau:

```sh
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
```

- Configure Ubuntu Cloud Archive repository

```sh
cat << EOF >> /etc/apt/sources.list.d/cloudarchive-mitaka.list 

# Ubuntu Cloud Archive
deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/mitaka main
EOF
```

- Update

```sh
apt-get update
apt-get install ubuntu-cloud-keyring
```

- Configure DataStax repository 

```sh
cat << EOF >  /etc/apt/sources.list.d/datastax.list
# DataStax (Apache Cassandra)
deb http://debian.datastax.com/community 2.2 main
EOF
```

- Download and install the repository’s key:

```sh
curl -L https://debian.datastax.com/debian/repo_key | apt-key add -
```

# Configure Java 8 repository

```sh
cat << EOF > /etc/apt/sources.list.d/openjdk-8.list
# OpenJDK 8
deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main
EOF
```

- Download and install the repository’s key:

```sh
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x86F44E2A
```

- Configure MidoNet repositories

```sh
cat << EOF > /etc/apt/sources.list.d/midonet.list
# MidoNet
deb http://builds.midonet.org/midonet-5.2 stable main

# MidoNet OpenStack Integration
deb http://builds.midonet.org/openstack-mitaka stable main

# MidoNet 3rd Party Tools and Libraries
deb http://builds.midonet.org/misc stable main
EOF
```

- Download and install the repositories' key:

```sh
curl -L https://builds.midonet.org/midorepo.key | apt-key add -
```

- Update Ubuntu

```sh
apt-get update
apt-get -y dist-upgrade
init 6
```