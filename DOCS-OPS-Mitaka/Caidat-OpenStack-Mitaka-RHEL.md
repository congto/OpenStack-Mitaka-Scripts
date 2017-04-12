# Cài đặt openStack Mitaka
***


# I. Cài đặt cơ bản
***

## 1. Chuẩn bị môi trường

## 1.1. Mô hình 2 node 
![Mitaka-topo-2node.png](./images/openstack-mitaka-network-layout-rhel.png)


### 1.2. Các tham số phần cứng đối với các node
- đang cập nhật

### 1.3. Phân hoạch IP với các node
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

#### 2.2.1.1 Sửa file cấu hình keystone

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

#### 2.2.1.2 Cấu hình APACHE cho keystone sử dụng

- Sửa file `/etc/httpd/conf/httpd.conf` với dòng dưới

	```
	echo "ServerName 10.10.10.40" >>   /etc/httpd/conf/httpd.conf
	```

- Sử dụng lệnh cat ở dưới để tạo file `/etc/httpd/conf.d/wsgi-keystone.conf` với nội dung dưới

	```sh
	cat << EOF > /etc/httpd/conf.d/wsgi-keystone.conf
	Listen 5000
	Listen 35357

	<VirtualHost *:5000>
	    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
	    WSGIProcessGroup keystone-public
	    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
	    WSGIApplicationGroup %{GLOBAL}
	    WSGIPassAuthorization On
	    ErrorLogFormat "%{cu}t %M"
	    ErrorLog /var/log/httpd/keystone-error.log
	    CustomLog /var/log/httpd/keystone-access.log combined

	    <Directory /usr/bin>
	        Require all granted
	    </Directory>
	</VirtualHost>

	<VirtualHost *:35357>
	    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
	    WSGIProcessGroup keystone-admin
	    WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
	    WSGIApplicationGroup %{GLOBAL}
	    WSGIPassAuthorization On
	    ErrorLogFormat "%{cu}t %M"
	    ErrorLog /var/log/httpd/keystone-error.log
	    CustomLog /var/log/httpd/keystone-access.log combined

	    <Directory /usr/bin>
	        Require all granted
	    </Directory>
	</VirtualHost>
	EOF
	```
- Kiểm tra lại nội dung file `/etc/httpd/conf.d/wsgi-keystone.conf` vừa tạo

	```sh
	cat /etc/httpd/conf.d/wsgi-keystone.conf
	```

- Khởi động và kích hoạt dịch vụ HTTP

	```sh
	systemctl enable httpd.service
	systemctl start httpd.service
	```

#### 2.2.2. Tạo endpoint cho keystone

- Khai báo các biến môi trường cần thiết cho keystone

	```sh
	export OS_TOKEN=Welcome123
	export OS_URL=http://10.10.10.40:35357/v3
	export OS_IDENTITY_API_VERSION=3
	```

- Tạo service cho keystone

	```sh
	openstack service create --name keystone --description "OpenStack Identity" identity
	```

- Tạo các `endpoint` cho dịch vụ keystone

	```sh
	 openstack endpoint create --region RegionOne identity public http://10.10.10.40:5000/v3

	 openstack endpoint create --region RegionOne identity internal http://10.10.10.40:5000/v3

	 openstack endpoint create --region RegionOne identity admin http://10.10.10.40:35357/v3
	```

#### 2.2.3. Tạo `domain, projects, users` và `roles` cho OpenStack

- Tạo domain cho keystone

	```sh
	openstack domain create --description "Default Domain" default
	```

- Tạo project tên là `admin`

	```sh
	openstack project create --domain default --description "Admin Project" admin
	```

- Tạo user tên là `admin` và password là `Welcome123`

	```sh
	openstack user create admin --domain default --password Welcome123
	```

- Tạo role tên là `admin`

	```sh
	openstack role create admin
	```

- Gán role `admin` cho project `admin` và user `admin`

	```sh
	openstack role add --project admin --user admin admin
	```

- Tạo project tên là `serivce` 

	```sh
	openstack project create --domain default  --description "Service Project" service
	```

- Tạo project tên là `demo`

	```sh
	openstack project create --domain default --description "Demo Project" demo
	```

- Tạo user tên là `demo` và password là `Wecome123`

	```sh
	openstack user create demo --domain default --password Welcome123
	```

- Tạo rule tên là `user`

	```sh
	openstack role create user
	```

- Gán role `user` cho user và project `demo`

	```sh
	openstack role add --project demo --user demo user
	```


#### 2.2.4. Xác nhận lại keystone vừa cài đặt đã hoạt động

- Bỏ các biến môi trường `OS_TOKEN` và `OS_URL`

	```sh
	unset OS_TOKEN OS_URL
	```

- Tạo file chứa biến môi trường dành cho tài khoản `admin` bằng đoạn lệnh dưới

	```sh
	cat << EOF > admin-openrc
	export OS_PROJECT_DOMAIN_NAME=default
	export OS_USER_DOMAIN_NAME=default
	export OS_PROJECT_NAME=admin
	export OS_USERNAME=admin
	export OS_PASSWORD=Welcome123
	export OS_AUTH_URL=http://10.10.10.40:35357/v3
	export OS_IDENTITY_API_VERSION=3
	export OS_IMAGE_API_VERSION=2
	EOF
	```


- Tạo file chứa biến môi trường dành cho tài khoản `demo` bằng đoạn lệnh dưới

	```sh
	cat << EOF > admin-openrc
	export OS_PROJECT_DOMAIN_NAME=default
	export OS_USER_DOMAIN_NAME=default
	export OS_PROJECT_NAME=demo
	export OS_USERNAME=demo
	export OS_PASSWORD=Welcome123
	export OS_AUTH_URL=http://10.10.10.40:5000/v3
	export OS_IDENTITY_API_VERSION=3
	export OS_IMAGE_API_VERSION=2
	EOF
	```

- Thực thi biến môi trường. Lưu ý: Bước này được thực hiện mỗi khi sử dụng lệnh của OpenStack

	```sh
	. admin-openrc
	```

- Kiểm tra xem `keystone` đã hoạt động hay chưa

	```sh
	openstack token issue
	```

- Kết quả như sau:

	```sh
	+------------+-----------------------------------------------------------------+
	| Field      | Value                                                           |
	+------------+-----------------------------------------------------------------+
	| expires    | 2016-02-12T20:44:35.659723Z                                     |
	| id         | gAAAAABWvjYj-Zjfg8WXFaQnUd1DMYTBVrKw4h3fIagi5NoEmh21U72SrRv2trl |
	|            | JWFYhLi2_uPR31Igf6A8mH2Rw9kv_bxNo1jbLNPLGzW_u5FC7InFqx0yYtTwa1e |
	|            | eq2b0f6-18KZyQhs7F3teAta143kJEWuNEYET-y7u29y0be1_64KYkM7E       |
	| project_id | 343d245e850143a096806dfaefa9afdc                                |
	| user_id    | ac3377633149401296f6c0d92d79dc16                                |
	+------------+-----------------------------------------------------------------+
	```


### 2.3. Cài đặt và cấu hình `GLANCE`


#### 2.3.1. Cài đặt database cho `GLANCE`

- Tạo database cho dịch vụ `Glance` bằng đoạn lệnh dưới.

	```sh
	cat << EOF | mysql -uroot -pWelcome123
	CREATE DATABASE glance;
	GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'Welcome123';
	GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'Welcome123';
	FLUSH PRIVILEGES;
	EOF
	```

#### 2.3.2. Tạo user, endpoint cho dịch vụ GLANCE

- Thực thi biến môi trường để tương tác với OpenStack

	```sh
	source /root/admin-openrc
	```

- Tạo user tên là `glance` và có mật khẩu là `Welcome123`

	```sh
	openstack user create  glance --domain default --password Welcome123
	```

- Gán role `admin` cho user `glance` vào trong project `service`

	```sh
	openstack role add --project service --user glance admin
	```


- Tạo service tên là `glance`

	```sh
	openstack service create --name glance --description "OpenStack Image" image
	```

- Tạo các endpoint cho dịch vụ `glance`

```sh
openstack endpoint create --region RegionOne image public http://10.10.10.40:9292

openstack endpoint create --region RegionOne image internal http://10.10.10.40:9292

openstack endpoint create --region RegionOne image admin http://10.10.10.40:9292
```

#### 2.3.3. Cài đặt và cấu hình dịch vụ `GLANCE`

- Cài đặt các gói 

```sh
yum install -y openstack-glance
```

#### 2.3.3.1. Sửa file /etc/glance/glance-api.conf

- Sao lưu file cấu hình của glance `/etc/glance/glance-api.conf`

	```sh
	cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.orig
	```

- Khai báo các dòng dưới trong section `[database]` của file 

	```sh
	connection = mysql+pymysql://glance:Welcome123@10.10.10.40/glance
	```

- Khai báo các dòng dưới trong section `[keystone_authtoken]`

	```sh
	auth_uri = http://10.10.10.40:5000
	auth_url = http://10.10.10.40:35357
	memcached_servers = 10.10.10.40:11211
	auth_type = password
	project_domain_name = default
	user_domain_name = default
	project_name = service
	username = glance
	password = Welcome123
	```

- Khai báo dòng dưới trong section `[paste_deploy]`

	```sh
	flavor = keystone
	```

- Khai báo các dòng dưới trong section `[glance_store]`

```sh
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
```

#### 2.3.3.2. Sửa file `/etc/glance/glance-registry.conf`

- Sao lưu file `/etc/glance/glance-registry.conf`

	```sh
	cp /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.orig
	```

- Khai báo các dòng dưới trong section `[database]`

	```sh
	connection = mysql+pymysql://glance:Welcome123@10.10.10.40/glance
	```

- Khai báo các dòng dưới trong section `[keystone_authtoken]`

	```sh
	auth_uri = http://controller:5000
	auth_url = http://controller:35357
	memcached_servers = controller:11211
	auth_type = password
	project_domain_name = default
	user_domain_name = default
	project_name = service
	username = glance
	password = Welcome123
	```

- Khai báo các dòng dưới trong section `[paste_deploy]`

	```sh
	flavor = keystone
	```

- Tạo các bảng trong database cho dịch vụ `glance`

```sh
su -s /bin/sh -c "glance-manage db_sync" glance
```

- Khởi động và kích hoạt dịch vụ của glance

	````sh
	systemctl enable openstack-glance-api.service  openstack-glance-registry.service
	systemctl start openstack-glance-api.service openstack-glance-registry.service
	```

- Kiểm tra lại dịch vụ glance