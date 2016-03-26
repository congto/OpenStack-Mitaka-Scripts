# Cài đặt openStack Mitaka

<a name="1"> </a> 
## 1. Chuẩn bị môi trường
<a name="1.1"> </a> 
### 1.1 Mô hình mạng

![OpenStack Mitaka Topo](/DOCS-OPS-Mitaka/images/Mitaka-topo.png)

<a name="1.2"> </a> 
### 1.2 Các tham số phần cứng đối với các node
![OpenStack Mitaka Topo](/DOCS-OPS-Mitaka/images/Mitaka-ip-hardware.png)

<a name="2"> </a> 
## 2. Cài đặt trên node controller
===
- Lưu ý:
 - Đăng nhập với quyền root trên tất cả các bước cài đặt.
 - Các thao tác sửa file trong hướng dẫn này sử dụng lệnh `vi` hoặc `vim`
 - Password thống nhất cho tất cả các dịch vụ là `Welcome123`

<a name="2.1"> </a>  
### 2.1 Cài đặt các thành phần chung
===
<a name="2.1.1"> </a> 
#### 2.1.1 Thiết lập và cài đặt các gói cơ bản

- Chạy lệnh để cập nhật các gói phần mềm
	```sh
	apt-get -y update
	```

- Thiết lập địa chỉ IP
- Dùng lệnh `vi` để sửa file `/etc/network/interface` với nội dung như sau.

	```sh
	# Interface MGNT
	auto eth0
	iface eth0 inet static
		address 10.10.10.40
		netmask 255.255.255.0

	# Interface EXT
	auto eth1
	iface eth1 inet static
		address 172.16.69.40
		netmask 255.255.255.0
		gateway 172.16.69.1
		dns-nameservers 8.8.8.8
	```

- Khởi động lại card mạng sau khi thiết lập IP tĩnh
	```sh
	ifdown -a && ifup -a
	```
- Kiểm tra kết nối tới gateway và internet sau khi thiết lập xong.
	```sh
	ping 172.16.69.1 -c 4
	PING 172.16.69.1 (172.16.69.1) 56(84) bytes of data.
	64 bytes from 172.16.69.1: icmp_seq=1 ttl=64 time=0.253 ms
	64 bytes from 172.16.69.1: icmp_seq=2 ttl=64 time=0.305 ms
	64 bytes from 172.16.69.1: icmp_seq=3 ttl=64 time=0.306 ms
	64 bytes from 172.16.69.1: icmp_seq=4 ttl=64 time=0.414 ms
	```
	
	```sh
	ping google.com -c 4
	PING google.com (74.125.204.113) 56(84) bytes of data.
	64 bytes from ti-in-f113.1e100.net (74.125.204.113): icmp_seq=1 ttl=41 time=58.3 ms
	64 bytes from ti-in-f113.1e100.net (74.125.204.113): icmp_seq=2 ttl=41 time=58.3 ms
	64 bytes from ti-in-f113.1e100.net (74.125.204.113): icmp_seq=3 ttl=41 time=58.3 ms
	64 bytes from ti-in-f113.1e100.net (74.125.204.113): icmp_seq=4 ttl=41 time=58.3 ms
	```
- Cấu hình hostname
- Dùng `vi` sửa file `/etc/hostname` với tên là `controller`
	```sh
	controller
	```
- Cập nhật file `/etc/hosts` để phân giải từ IP sang hostname và ngược lại, nội dung như sau

	```sh
	127.0.0.1      localhost controller
	10.10.10.40    controller
	10.10.10.41    compute1
	```

<a name="2.1.2"> </a> 
#### 2.1.2 Cài đặt NTP
- Cài gói `chrony`
	```sh
	apt-get -y install chrony
	```
	
- Sửa file  `/etc/chrony/chrony.conf`
	```sh
	server 1.vn.pool.ntp.org iburst
	server 0.asia.pool.ntp.org iburst
	server 3.asia.pool.ntp.org iburst
	```

- Khởi động lại dịch vụ NTP

<a name="2.1.3"> </a> 
#### 2.1.3 Cài đặt repos để cài OpenStack Mitaka

- Cài đặt gói để cài OpenStack Mitaka
	```sh
	apt-get install software-properties-common -y
	add-apt-repository cloud-archive:mitaka -y
	```

- Cập nhật các gói phần mềm
	```sh
	apt-get -y update && apt-get -y dist-upgrade
	```
	
- Cài đặt các gói client của OpenStack
	```sh
	apt-get -y install python-openstackclient
	```

- Khởi động lại máy chủ
	```sh
	init 6
	```
- Đăng nhập lại và chuyển sang quyền `root` và thực hiện các bước tiếp theo.
	
<a name="2.1.4"> </a> 
#### 2.1.4 Cài đặt SQL database

- Cài đặt MariaDB
	```sh
	su -
	
	apt-get -y install mariadb-server python-pymysql
	```
- Trong quá trình cài MariaDB, hệ thống yêu cầu người dùng nhập mật khẩu vào ô sau

![MariaDB password](/DOCS-OPS-Mitaka/images/mitaka-mariadb01.png)

Hãy nhập password là `Welcome123` để thống nhất cho toàn bộ các bước.

- Cấu hình cho MariaDB, tạo file  `/etc/mysql/conf.d/openstack.cnf` với nội dung sau

	```sh
	[mysqld]
	bind-address = 10.10.10.40
	default-storage-engine = innodb
	innodb_file_per_table
	collation-server = utf8_general_ci
	character-set-server = utf8
	```

- Khởi động lại MariaDB
	```sh
	service mysql restart
	```

- Nếu cần thiết thực hiện bước dưới và làm theo để thiết lập cơ bản cho MariaDB
	```sh
	mysql_secure_installation
	```
- Đăng nhập bằng tài khoản `root` vào `MariaDB` để kiểm tra lại. Sau đó gõ lệnh `exit` để thoát.
	```sh
	root@controller:~# mysql -u root -p
	Enter password:
	Welcome to the MariaDB monitor.  Commands end with ; or \g.
	Your MariaDB connection id is 29
	Server version: 5.5.47-MariaDB-1ubuntu0.14.04.1 (Ubuntu)

	Copyright (c) 2000, 2015, Oracle, MariaDB Corporation Ab and others.

	Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

	MariaDB [(none)]>
	MariaDB [(none)]>
	MariaDB [(none)]> exit;
	```

<a name="2.1.5"> </a> 	
#### 2.1.5 Cài đặt RabbitMQ
- Cài đặt gói
	```sh
	apt-get -y install rabbitmq-server
	```
-Cấu hình RabbitMQ, tạo user `openstack` với mật khẩu là `Welcome123`
	```sh
	rabbitmqctl add_user openstack Welcome123
	```

- Gán quyền read, write cho tài khoản `openstack` trong `RabbitMQ`
	```sh
	rabbitmqctl set_permissions openstack ".*" ".*" ".*"
	```

<a name="2.1.6"> </a> 
#### 2.1.6 Cài đặt Memcached
- Cài đặt các gói cần thiết cho `memcached`

	```sh
	apt-get -y install memcached python-memcache
	```
	
- Dùng vi sửa file `/etc/memcached.conf`, thay dòng `-l 127.0.0.1` bằng dòng dưới.

	```sh
	-l 10.10.10.40
	```

- Khởi động lại `memcache`
	```sh
	service memcached restart
	```
	
<a name="2.2"> </a> 	
### 2.2 Cài đặt Keystone
===
<a name="2.2.1"> </a> 
#### 2.2.1 Tạo database cho keystone
- Đăng nhập vào MariaDB

	```sh
	mysql -u root -p
	```

- Tạo user, database cho keystone

	```sh
	CREATE DATABASE keystone;
	GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost'  IDENTIFIED BY 'Welcome123';
	GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'Welcome123';
	FLUSH PRIVILEGES;
	
	exit;
	```

<a name="2.2.2"> </a> 
#### 2.2.2 Cài đặt và cấu hình `keystone`
- Không cho `keystone` khởi động tự động sau khi cài
	```sh
	echo "manual" > /etc/init/keystone.override
	```
- Cài đặt gói cho `keystone`

	```sh
	apt-get -y install keystone apache2 libapache2-mod-wsgi
	```

- Sao lưu file cấu hình của dịch vụ keystone trước khi chỉnh sửa.

	```sh
	cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.orig
	```

- Dùng lệnh `vi` để mở và sửa file `/etc/keystone/keystone.conf`.

 - Trong section `[DEFAULT]` khai báo dòng
 
		```sh
		admin_token = Welcome123
		```
	
 - Trong section `[database]` thay dòng `connection = sqlite:////var/lib/keystone/keystone.db` bằng dòng dưới
 
		```sh
		connection = mysql+pymysql://keystone:Welcome123@10.10.10.40/keystone
		```
	
 - Sửa file `[token]`
 
		```sh
		provider = fernet
		```
	
- Đồng bộ database cho keystone
	```sh
	su -s /bin/sh -c "keystone-manage db_sync" keystone
	```
	- Lệnh trên sẽ tạo ra các bảng trong database có tên là keysonte

- Thiết lập `Fernet` key

	```sh
	keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
	```

<a name="2.2.3"> </a> 
#### 2.2.3 Cấu hình apache cho `keysonte`

- Dùng `vi` để mở và sửa file `/etc/apache2/apache2.conf`. Thêm dòng dưới ngay sau dòng `# Global configuration`

	```sh
	# Global configuration
	ServerName controller
	```

- Sử dụng `vi` để tạo file `/etc/apache2/sites-available/wsgi-keystone.conf` chứa nội dung dưới

	```sh
	Listen 5000
	Listen 35357

	<VirtualHost *:5000>
		WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
		WSGIProcessGroup keystone-public
		WSGIScriptAlias / /usr/bin/keystone-wsgi-public
		WSGIApplicationGroup %{GLOBAL}
		WSGIPassAuthorization On
		<IfVersion >= 2.4>
		  ErrorLogFormat "%{cu}t %M"
		</IfVersion>
		ErrorLog /var/log/apache2/keystone.log
		CustomLog /var/log/apache2/keystone_access.log combined

		<Directory /usr/bin>
			<IfVersion >= 2.4>
				Require all granted
			</IfVersion>
			<IfVersion < 2.4>
				Order allow,deny
				Allow from all
			</IfVersion>
		</Directory>
	</VirtualHost>

	<VirtualHost *:35357>
		WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
		WSGIProcessGroup keystone-admin
		WSGIScriptAlias / /usr/bin/keystone-wsgi-admin
		WSGIApplicationGroup %{GLOBAL}
		WSGIPassAuthorization On
		<IfVersion >= 2.4>
		  ErrorLogFormat "%{cu}t %M"
		</IfVersion>
		ErrorLog /var/log/apache2/keystone.log
		CustomLog /var/log/apache2/keystone_access.log combined

		<Directory /usr/bin>
			<IfVersion >= 2.4>
				Require all granted
			</IfVersion>
			<IfVersion < 2.4>
				Order allow,deny
				Allow from all
			</IfVersion>
		</Directory>
	</VirtualHost>
	```

- Tạo link để cấu hình virtual host cho dịch vụ `keysonte` trong `apache`
	```sh
	ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
	```

- Khởi động lại `apache`
	```sh
	service apache2 restart
	```

- Xóa file database mặc định của `keysonte` 
	```sh
	rm -f /var/lib/keystone/keystone.db
	```

<a name="2.3"> </a> 
### 2.3 Tạo endpoint và các service cho `keysonte`

<a name="2.3.1"> </a> 
#### 2.3.1 Khai báo xác thực chung 
- Khai báo sử dụng `token` để xác thực.

	```sh
	export OS_TOKEN=Welcome123
	export OS_URL=http://controller:35357/v3
	export OS_IDENTITY_API_VERSION=3
	```

<a name="2.3.2"> </a> 
#### 2.3.2 Khai báo xác thực chung 
- Tạo các service và endpoint cho `keysonte`
	```sh
	openstack service create \
	  --name keystone --description "OpenStack Identity" identity
	```

- Tạo các endpoint
	```sh
	openstack endpoint create --region RegionOne identity public http://controller:5000/v3
	  
	openstack endpoint create --region RegionOne identity internal http://controller:5000/v3
	  
	openstack endpoint create --region RegionOne identity admin http://controller:35357/v3
	```

<a name="2.4"> </a> 
### 2.4 Tạo domain, projects, users, and roles

- Tạo domain

	```sh
	openstack domain create --description "Default Domain" default
	```

- Tạo `admin` project

	```sh
	openstack project create --domain default  --description "Admin Project" admin
	```

- Tạo user `admin`
	```sh
	openstack user create --domain default --password-prompt admin
	```

- Tạo role `admin`
	```sh
	openstack role create admin
	```

- Gán user `admin` vào role `admin` thuộc project `admin`
	```sh
	openstack role add --project admin --user admin admin
	```

- Tạo project có tên là `service` để chứa các user service của openstack
	```sh
	openstack project create --domain default --description "Service Project" service
	```

 
- Tạo project tên là `demo`
	```sh
	openstack project create --domain default --description "Demo Project" demo
	```

- Tạo user tên là `demo`
	```sh
	 openstack user create --domain default --password-prompt demo
	```

- Tạo role tên là `user`
	```sh
	openstack role create user
	```

- Gán tài khoản `demo` có role là `user` vào project `demo`
	```sh
	openstack role add --project demo --user demo user
	```

<a name="2.5"> </a> 
### 2.5 Kiểm chứng lại các bước cài đặt `keysonte`

- Vô hiệu hóa cơ chế xác thực bằng token tạm thời trong `keysonte` bằng cách chỉnh sửa dòng `admin_token_auth` trong các section `[pipeline:public_api]`,  `[pipeline:admin_api]`  và `[pipeline:api_v3]` của file `/etc/keystone/keystone-paste.ini`

- Bỏ thiết lập trong biến môi trường của `OS_TOKEN` và `OS_URL` bằng lệnh
	```sh
	unset OS_TOKEN OS_URL
	```

- Gõ lần lượt 2 lệnh dưới để nhận kết quả trả về
	```sh
	openstack --os-auth-url http://controller:35357/v3 \
	--os-project-domain-name default --os-user-domain-name default \
	--os-project-name admin --os-username admin token issue

	và 

	openstack --os-auth-url http://controller:5000/v3 \
	--os-project-domain-name default --os-user-domain-name default \
	--os-project-name demo --os-username demo token issue
	```

<a name="2.6"> </a> 
### 2.6 Tạo script biến môi trường cho client 

- Tạo file `admin-openrc` chứa nội dung sau
	```sh
	export OS_PROJECT_DOMAIN_NAME=default
	export OS_USER_DOMAIN_NAME=default
	export OS_PROJECT_NAME=admin
	export OS_USERNAME=admin
	export OS_PASSWORD=ADMIN_PASS
	export OS_AUTH_URL=http://controller:35357/v3
	export OS_IDENTITY_API_VERSION=3
	```

- Tạo file `demo-openrc` chứa nội dung sau
	```sh
	export OS_PROJECT_DOMAIN_NAME=default
	export OS_USER_DOMAIN_NAME=default
	export OS_PROJECT_NAME=demo
	export OS_USERNAME=demo
	export OS_PASSWORD=DEMO_PASS
	export OS_AUTH_URL=http://controller:5000/v3
	export OS_IDENTITY_API_VERSION=3
	```	

- Chạy script `admin-openrc`
	```sh
	source  admin-openrc
	```

- Gõ lệnh dưới để kiểm tra biến môi trường ở trên đã chính xác hay chưa
	```sh
	openstack token issue
	```

- Kết quả sẽ như bên dưới (Lưu ý: giá trị sẽ khác nhau)
	```sh
	Kết quả 
	```