# Cài đặt openStack Mitaka
***


# I. Cài đặt cơ bản
***

## 1. Chuẩn bị môi trường

## 1.1. Mô hình 2 node 
![Mitaka-topo-2node.png](./images/openstack-mitaka-network-layout-rhel.png)


### 1.2. Các tham số phần cứng đối với các node
- đang cập nhật

### 1.2.3 Phân hoạch IP với các node
- Xem trong file topo đã điền sẵn. Trong lab này chỉ đặt default gateway cho card mạng gắn vào dải `172.16.69.0/24`

## 2. Cài đặt trên node controller
===
- Lưu ý:
 - Đăng nhập với quyền root trên tất cả các bước cài đặt.
 - Các thao tác sửa file trong hướng dẫn này sử dụng lệnh `vi` hoặc `vim`
 - Password thống nhất cho tất cả các dịch vụ là `Welcome123`

### 2.1. Cài đặt các thành phần chung
===

### 2.1.1. Thiết lập các thành phần cơ bản

- Ngắt firewall

```sh
systemctl stop firewalld 
systemctl disable firewalld 
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
```

- Đặt IP cho các card mạng `Management + API`

```sh
nmcli c modify eno16777728 ipv4.addresses 10.10.10.40/24
nmcli c modify eno16777728 ipv4.method manual
```

- Đặt IP cho các card mạng `External`

```sh
nmcli c modify eno33554952 ipv4.addresses 172.16.69.40/24
nmcli c modify eno33554952 ipv4.gateway 172.16.69.1
nmcli c modify eno33554952 ipv4.dns 8.8.8.8
nmcli c modify eno33554952 ipv4.method manual
```

- Sửa hostname cho controller node

```sh
hostnamectl set-hostname controller
```

- Khai báo hostname

```sh
cat << EOF >> /etc/hosts
127.0.0.1       localhost controller
10.10.10.40   controller
10.10.10.41  compute1
EOF
```

### 2.1.2. Khai báo repos cho OpenStack Mitaka

- Tải gói

```sh
yum install -y https://repos.fedorapeople.org/repos/openstack/openstack-mitaka/rdo-release-mitaka-6.noarch.rpm
yum -y upgrade
```

- Cài các gói bổ trợ

```sh
yum -y install python-openstackclient
yum -y install openstack-selinux
yum -y install wget 
```

- Khởi động lại máy chủ controller

```sh
init 6
```


### 2.1.2. Cài đặt chrony (Network Time Protocol)

- Cài gói cần thiết

```sh
yum install -y chrony
```

- Sao lưu file `/etc/chrony.conf`

```sh
cp /etc/chrony.conf /etc/chrony.conf.orig
```

- Sửa file các dòng dưới trong file `/etc/chrony.conf`

```
sed -i 's/server 0.rhel.pool.ntp.org iburst/server 10.10.10.40 iburst/g' /etc/chrony.conf
sed -i 's/server 1.rhel.pool.ntp.org iburst/#server 1.centos.pool.ntp.org iburst/g' /etc/chrony.conf
sed -i 's/server 2.rhel.pool.ntp.org iburst/#server 2.centos.pool.ntp.org iburst/g' /etc/chrony.conf
sed -i 's/server 3.rhel.pool.ntp.org iburst/#server 3.centos.pool.ntp.org iburst/g' /etc/chrony.conf
sed -i 's/#allow 192.168\/16/allow 10.10.10.0\/24/g' /etc/chrony.conf
```

- Khởi động lại dịch vụ rabbit

```sh
systemctl enable chronyd.service
systemctl start chronyd.service
```

- Kiểm tra trạng thái

```sh
chronyc sources
```

### 2.1.2. Cài đặt RabbitmQ

- Cài đặt và khởi động lại các gói RABBITMQ

```sh
yum -y install rabbitmq-server

systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service
```

- Tạo user `openstack` và đặt mật khẩu `Welcome123` cho RabbitMQ

```sh
rabbitmqctl add_user openstack Welcome123
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
```


### 2.1.3. Cài đặt Database `MariaDB`

- Cài đặt MariaDB

```
yum -y install mariadb mariadb-server python2-PyMySQL
```

- Cấu hình cho MariaDB

```
touch /etc/my.cnf.d/openstack.cnf

cat << EOF > /etc/my.cnf.d/openstack.cnf
[mysqld]
bind-address = 0.0.0.0

default-storage-engine = innodb
innodb_file_per_table
collation-server = utf8_general_ci
character-set-server = utf8

EOF
```

- Khởi động MYSQL

```sh
systemctl start mariadb.service
```

- Đặt mật khẩu `root` của mariadb

```
cat > /root/config.sql <<EOF
delete from mysql.user where user='';
update mysql.user set password=password("Welcome123");
flush privileges;
EOF

mysql -u root -e'source /root/config.sql'
rm -rf /root/config.sql
```

- Kích hoạt dịch vụ Mariadb

```sh
systemctl enable mariadb.service
```

### 2.1.3. Installing memcached


```sh
yum -y install memcached python-memcached

systemctl enable memcached.service
systemctl start memcached.service
```

### 2.2. Cài đặt  và cấu hình keystone
===

- Tạo DB cho keystone

```sh
cat << EOF | mysql -uroot -pWelcome123
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'Welcome123';
FLUSH PRIVILEGES;
EOF
```

#### 2.2.1 Cài đặt keystone

```sh
yum -y install openstack-keystone httpd mod_wsgi
```

#### 2.2.2 Sửa file cấu hình keystone

- Sao lưu file cấu hình của keystone

	```sh
	cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.orig
	```

- Sửa trong section `[DEFAULT]` các dòng dưới

	```sh
	admin_token = Welcome123
	```

- Sửa trong section `[database]` các dòng dưới:

	```sh
	connection = mysql+pymysql://keystone:Welcome123@10.10.10.40/keystone
	```

- Sửa trong section `[token]` các dòng dưới:

	```sh
	provider = fernet
	```

- Tạo các bảng dữ liệu trong database của keystone

	```sh
	su -s /bin/sh -c "keystone-manage db_sync" keystone
	```

- Thiết lập bộ key cho `Fernet` trong keystone

```sh
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
```

#### 2.2.3 Cấu hình APACHE cho keystone sử dụng

- Sửa file `/etc/httpd/conf/httpd.conf` với dòng dưới

```sh
ServerName 10.10.10.40
```

