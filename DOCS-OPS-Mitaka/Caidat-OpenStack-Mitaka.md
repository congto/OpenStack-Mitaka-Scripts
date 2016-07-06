# Cài đặt openStack Mitaka
***

<a name="I."> </a> 
# I. Cài đặt cơ bản
***
<a name="1"> </a> 
## 1. Chuẩn bị môi trường
<a name="1.1"> </a> 
### 1.1 Mô hình mạng
- Mô hình đầy đủ
![OpenStack Mitaka Topo](/DOCS-OPS-Mitaka/images/Mitaka-topo.png)

<a name="1.2"> </a> 
### 1.2 Các tham số phần cứng đối với các node
![OpenStack Mitaka Topo](/DOCS-OPS-Mitaka/images/Mitaka-ip-hardware.png)

## Mô hình 2 node 
![Mitaka-topo-2node.png](./images/Mitaka-topo-2node.png)

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
- Dùng lệnh `vi` để sửa file `/etc/network/interfaces` với nội dung như sau.

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

- Đăng nhập lại máy `Controller` với quyền `root` và thực hiện kiểm tra kết nối. 
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
	
- Mở file `/etc/chrony/chrony.conf` và tìm các dòng dưới

	```sh
	server 0.debian.pool.ntp.org offline minpoll 8
	server 1.debian.pool.ntp.org offline minpoll 8
	server 2.debian.pool.ntp.org offline minpoll 8
	server 3.debian.pool.ntp.org offline minpoll 8
	```

- Thay bằng các dòng sau 

	```sh
	server 1.vn.pool.ntp.org iburst
	server 0.asia.pool.ntp.org iburst
	server 3.asia.pool.ntp.org iburst
	```

- Khởi động lại dịch vụ NTP
	```sh
	service chrony restart
	```

- Kiểm tra lại hoạt động của NTP bằng lệnh dưới
	```sh
	root@controller:~# chronyc sources
	```
	
	- Kết quả như sau
	
		```sh
		210 Number of sources = 3
		MS Name/IP address         Stratum Poll Reach LastRx Last sample
		===============================================================================
		^+ 220.231.122.105               3   6    17    16    +12ms[+4642us] +/-  139ms
		^* 103.245.79.2                  2   6    17    17    -10ms[  -12ms] +/-  176ms
		^? routerida1.soprano-asm.ne     0   6     0   10y     +0ns[   +0ns] +/-    0ns
		root@controller:~#
		```

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
	
<a name="3"> </a> 	
## 3. Cài đặt Keystone
***
<a name="3.1."> </a> 
### 3.1 Cài đặt và cấu hình cho keysonte
***

<a name="3.1.1."> </a> 
#### 3.1.1. Tạo database cài đặt các gói và cấu hình keystone
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

<a name="3.1.2."> </a> 
#### 3.1.2. Cài đặt và cấu hình `keystone`
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

- Cấu hình apache cho `keysonte`

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

<a name="3.1.3."> </a> 
#### 3.1.3. Tạo endpoint và các service cho `keysonte`


- Khai báo sử dụng `token` để xác thực.

	```sh
	export OS_TOKEN=Welcome123
	export OS_URL=http://controller:35357/v3
	export OS_IDENTITY_API_VERSION=3
	```

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

<a name="3.1.4."> </a> 
#### 3.1.4. Tạo domain, projects, users, and roles

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
	openstack user create admin --domain default --password Welcome123
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
	openstack user create demo --domain default --password Welcome123
	```

- Tạo role tên là `user`
	```sh
	openstack role create user
	```

- Gán tài khoản `demo` có role là `user` vào project `demo`
	```sh
	openstack role add --project demo --user demo user
	```

<a name="3.1.5."> </a> 
#### 3.1.5. Kiểm chứng lại các bước cài đặt `keysonte`


- Vô hiệu hóa cơ chế xác thực bằng token tạm thời trong `keysonte` bằng cách xóa `admin_token_auth` trong các section `[pipeline:public_api]`,  `[pipeline:admin_api]`  và `[pipeline:api_v3]` của file `/etc/keystone/keystone-paste.ini`

- Bỏ thiết lập trong biến môi trường của `OS_TOKEN` và `OS_URL` bằng lệnh
	```sh
	unset OS_TOKEN OS_URL
	```

- Gõ lần lượt 2 lệnh dưới sau đó nhập mật khẩu
	```sh
	openstack --os-auth-url http://controller:35357/v3 \
	--os-project-domain-name default --os-user-domain-name default \
	--os-project-name admin --os-username admin token issue

	và 

	openstack --os-auth-url http://controller:5000/v3 \
	--os-project-domain-name default --os-user-domain-name default \
	--os-project-name demo --os-username demo token issue
	```

<a name="3.1.6."> </a> 
#### 3.1.6. Tạo script biến môi trường cho client 

- Tạo file `admin-openrc` chứa nội dung sau
	```sh
	cat << EOF > admin-openrc
	export OS_PROJECT_DOMAIN_NAME=default
	export OS_USER_DOMAIN_NAME=default
	export OS_PROJECT_NAME=admin
	export OS_USERNAME=admin
	export OS_PASSWORD=Welcome123
	export OS_AUTH_URL=http://controller:35357/v3
	export OS_IDENTITY_API_VERSION=3
	EOF
	```


- Tạo file `demo-openrc` chứa nội dung sau
	```sh
	cat << EOF > demo-openrc
	export OS_PROJECT_DOMAIN_NAME=default
	export OS_USER_DOMAIN_NAME=default
	export OS_PROJECT_NAME=demo
	export OS_USERNAME=demo
	export OS_PASSWORD=Welcome123
	export OS_AUTH_URL=http://controller:5000/v3
	export OS_IDENTITY_API_VERSION=3
	EOF
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
	root@controller:~# openstack token issue
	+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	| Field      | Value                                                                                                                                                                                   |
	+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	| expires    | 2016-03-26T23:10:06.916201Z                                                                                                                                                             |
	| id         | gAAAAABW9wi_SwsD6CLTlvIuBUtXbn1eHH8wTtthyWNzNlG2bKO-9e-VK2fRVdRJ4oKnJ1ceU72KyK_C7N9MSWVlyedP3tQucQW2dzxu_fKl5YeslehFjw-Phv2EhXTOWPc-Ga9l017T8SvwzG4pKWqM7BRNe11GP7DeTBDGVHxFOxXuh7OJ3iE |
	| project_id | 38b9ce7973634d83a0390f47f028ed32                                                                                                                                                        |
	| user_id    | 100f1bf64d184f22bd6babdd5929696c                                                                                                                                                        |
	+------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
	```

<a name="4."> </a> 	
### 4. Cài đặt Glance
***
`Glance` là dịch vụ cung cấp các image (các hệ điều hành đã được đóng gói sẵn), các image này sử dụng theo cơ chế template để tạo ra các máy ảo. )
- Lưu ý: Thư mục chứa các file images trong hướng dẫn này là `/var/lib/glance/images/`


- Glance có các thành phần sau: 
 - glance-api:
 - glance-registry:
 - Database:
 - Storage repository for image file:
 - Metadata definition service:


<a name="4.1."> </a> 	
### 4.1. Tạo database và endpoint cho `glance`
***
<a name="4.1.1."> </a> 
#### 4.1.1 Tạo database cho `glance`
- Đăng nhập vào mysql
```sh
mysql -uroot -pWelcome123
```

- Tạo database và gán các quyền cho user `glance` trong database
	```sh
	CREATE DATABASE glance;
	GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'Welcome123';
	GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'Welcome123';
	FLUSH PRIVILEGES;
		
	exit;
	```

<a name="4.1.2."> </a> 
#### 4.1.2. Cấu hình xác thực cho dịch vụ `glance`
- Tạo tài khoản `glance`
	```sh
	openstack user create glance --domain default --password Welcome123
	```

- Gán quyền `admin` và project `service` cho user `glance`
	```sh
	openstack role add --project service --user glance admin
	```

- Kiểm tra lại xem user `glance` có role là gì

    ```sh
    openstack role list --user glance --project service
    ```
	
- Tạo dịch vụ có tên là `glance`
	```sh
	openstack service create --name glance --description "OpenStack Image service" image
	```

- Tạo các endpoint cho dịch vụ `glance`
	```sh
	openstack endpoint create --region RegionOne image public http://controller:9292

	openstack endpoint create --region RegionOne image internal http://controller:9292

	openstack endpoint create --region RegionOne image admin http://controller:9292
	```

<a name="4.1.3."> </a> 
#### 4.1.3. Cài đặt các gói và cấu hình cho dịch vụ `glance`

- Cài đặt gói `glance`
	```sh
	apt-get -y install glance
	```

- Sao lưu các file `/etc/glance/glance-api.conf` và `/etc/glance/glance-registry.conf` trước khi cấu hình
	```sh
	cp /etc/glance/glance-api.conf /etc/glance/glance-api.conf.orig
	cp /etc/glance/glance-registry.conf /etc/glance/glance-registry.conf.orig
	```

- Sửa các mục dưới đây trong hai file `/etc/glance/glance-api.conf`

 - Trong section `[DEFAULT]`  thêm hoặc tìm và thay thế dòng cũ bằng dòng dưới để cho phép chế độ ghi log với `glance`
	 ```sh
	 verbose = true
	 ```
 
 - Trong section `[database]` :
 
 - Comment dòng 
	 ```sh
	 #sqlite_db = /var/lib/glance/glance.sqlite
	 ```
 - Thêm dòng dưới 
	 ```sh
	 connection = mysql+pymysql://glance:Welcome123@controller/glance
	 ```
 
 - Trong section `[keystone_authtoken]` sửa các dòng cũ thành dòng dưới
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
 
 - Trong section ` [paste_deploy]` khai báo dòng dưới
 
    ```sh
    flavor = keystone
    ```
 - Khai báo trong section `[glance_store]` nơi lưu trữ file image
 
    ```sh
    stores = file,http
    default_store = file
    filesystem_store_datadir = /var/lib/glance/images/
    ```

- Sửa các mục dưới đây trong hai file `/etc/glance/glance-registry.conf`
 - Trong section `[database]` :
 
 - Comment dòng 
	 ```sh
	 #sqlite_db = /var/lib/glance/glance.sqlite
	 ```
 - Thêm dòng dưới 
	 ```sh
	 connection = mysql+pymysql://glance:Welcome123@controller/glance
	 ```

 - Trong section `[keystone_authtoken]` sửa các dòng cũ thành dòng dưới
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

 - Trong section ` [paste_deploy]` khai báo dòng dưới
	 ```sh
	 flavor = keystone
	 ```
	
- Đồng bộ database cho glance
	```sh
	su -s /bin/sh -c "glance-manage db_sync" glance
	```

- Khởi động lại dịch vụ `Glance`
	```sh
	service glance-registry restart
	service glance-api restart
	```

- Xóa file database mặc định trong `glance`
	```sh
	rm -f /var/lib/glance/glance.sqlite
	```

<a name="4.2."> </a> 	
### 4.2. Kiểm chứng lại việc cài đặt `glance`
***

- Khai báo biến môi trường cho dịch vụ `glance`
	```sh
	echo "export OS_IMAGE_API_VERSION=2" | tee -a admin-openrc demo-openrc

	source admin-openrc
	```

- Tải file image cho `glance`
	```sh
	wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
	```

- Upload file image vừa tải về
	```sh
	openstack image create "cirros" \
	 --file cirros-0.3.4-x86_64-disk.img \
	 --disk-format qcow2 --container-format bare \
	 --public
	```

- Kiểm tra lại image đã có hay chưa
	```sh
	openstack image list
	```
	
- Nếu kết quả lệnh trên hiển thị như bên dưới thì dịch vụ `glance` đã cài đặt thành công.
	```sh
	root@controller:~# openstack image list
	+--------------------------------------+--------+--------+
	| ID                                   | Name   | Status |
	+--------------------------------------+--------+--------+
	| 19d53e24-2985-4f75-bd63-7568a5f2f10f | cirros | active |
	+--------------------------------------+--------+--------+
	root@controller:~#

	```

	
<a name="5."> </a> 	
### 5. Cài đặt NOVA (Compute service)
***

<a name="5.1."> </a> 	
### 5.1. Tóm tắt về dịch vụ `nova` trong OpenStack
***
- Đây là bước cài đặt các thành phần của `nova` trên máy chủ `Controller`
- `nova` đảm nhiệm chức năng cung cấp và quản lý tài nguyên trong OpenStack để cấp cho các VM. Trong hướng dẫn nãy sẽ sử dụng KVM làm hypervisor. Nova sẽ tác động vào KVM thông qua `libvirt`
- `nova` có các thành phần như sau: 
 - nova-api: 
 - nova-api-metadata: 
 - nova-compute:
 - nova-schedule:
 - nova-conductor:
 - nova-cert: 
 - nova-network:
 - nova-novncproxy: 
 - nova-spicehtml5proxy: 
 - nova-xvpvncproxy:
 - nova-cert: 
 - euca2ools: 
 - nova client: 
 - The queue:
 - SQL database: 
 
<a name="5.2."> </a> 	
### 5.2. Cài đặt và cấu hình `nova`
***

<a name="5.2.1."> </a> 
#### 5.2.1. Tạo database và endpoint cho `nova`

- Đăng nhập vào database với quyền `root`
	```sh
	mysql -uroot -pWelcome123
	```

- Tạo database
	```sh
	CREATE DATABASE nova_api;
	CREATE DATABASE nova;

	GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
	GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';
	GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'Welcome123';
	GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'Welcome123';

	FLUSH PRIVILEGES;

	exit;
	```
- Khai báo biến môi trường
	```sh
	source admin-openrc
	```

- Tạo user,  phân quyền và tạo endpoint cho dịch vụ nova
 - Tạo user có tên là `nova`
		```sh
		openstack user create nova --domain default  --password Welcome123
		```

 - Phân quyền cho tài khoản `nova`
		```sh
		openstack role add --project service --user nova admin
		```
 - Kiểm chứng lại xem tài khoản `nova` đã có quyền `admin` hay chưa bằng lệnh dưới
 
     ```sh
     openstack role list --user nova --project service
     ```
     
 - Tạo service có tên là `nova`
		```sh
		openstack service create --name nova --description "OpenStack Compute" compute
		```

 - Tạo endpoint
		```sh
		openstack endpoint create --region RegionOne compute public http://controller:8774/v2.1/%\(tenant_id\)s
		openstack endpoint create --region RegionOne compute internal http://controller:8774/v2.1/%\(tenant_id\)s
		openstack endpoint create --region RegionOne compute admin http://controller:8774/v2.1/%\(tenant_id\)s
		```

- Cài đặt các gói cho `nova` và cấu hình
	```sh
	apt-get -y install nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler
	```

- Sao lưu file `/etc/nova/nova.conf` trước khi cấu hình

	```sh
	cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
	```

- Sửa file `/etc/nova/nova.conf`. 
- Lưu ý: Trong trường hợp nếu có dòng khai bao trước đó thì tìm và thay thế, chưa có thì khai báo mới hoàn toàn. 
 - Khai báo trong section `[api_database]` dòng dưới, do section `[api_database]` chưa có nên ta khai báo thêm
		```sh
		[api_database]
		connection = mysql+pymysql://nova:Welcome123@controller/nova_api
		```

 - Khai báo trong section `[database]` dòng dưới. Do section `[database]` chưa có nên ta khai báo thêm.
		```sh
		[database]
		connection = mysql+pymysql://nova:Welcome123@controller/nova
		```
 
- Trong section `[DEFAULT]` : 

 - Thay dòng 
		```sh
		logdir=/var/log/nova
		```
		
 - Bằng dòng 
	 ```sh
	 log-dir=/var/log/nova
	 ```
		
 - Thay dòng 
	 ```sh
	 enabled_apis=ec2,osapi_compute,metadata
	 ```
	 
 - bằng dòng
	 ```sh
	 enabled_apis=osapi_compute,metadata
	 ```
	 
 - Bỏ dòng `verbose = True`

 - Trong section `[DEFAULT]` khai báo thêm các dòng sau:
	 ```sh
	 rpc_backend = rabbit
	 auth_strategy = keystone
	 rootwrap_config = /etc/nova/rootwrap.conf
	 #IP MGNT cua node Controller
	 my_ip = 10.10.10.40 
	
	 use_neutron = True
	 firewall_driver = nova.virt.firewall.NoopFirewallDriver
	 ```

 - Khai báo trong section `[oslo_messaging_rabbit]` các dòng dưới. Do section `[oslo_messaging_rabbit]` chưa có nên ta khai báo thêm.
	 ```sh
	 [oslo_messaging_rabbit]
	 rabbit_host = controller
	 rabbit_userid = openstack
	 rabbit_password = Welcome123
	 ```

 - Trong section `[keystone_authtoken]` khai báo các dòng dưới. Do section `[keystone_authtoken]` chưa có nên ta khai báo thêm.
	 ```sh
	 [keystone_authtoken]
	 auth_uri = http://controller:5000
	 auth_url = http://controller:35357
	 memcached_servers = controller:11211
	 auth_type = password
	 project_domain_name = default
	 user_domain_name = default
	 project_name = service
	 username = nova
	 password = Welcome123
	 ```

 - Trong section `[vnc]` khai báo các dòng dưới để cấu hình VNC điều khiển các máy ảo trên web.  Do section `[vnc]` chưa có nên ta khai báo thêm.
	 ```sh
	 [vnc]
	 vncserver_listen = $my_ip
	 vncserver_proxyclient_address = $my_ip
	 ```

 - Trong section `[glance]` khai báo dòng để nova kết nối tới API của glance. Do section `[glance]` chưa có nên ta khai báo thêm.
	 ```sh
	 [glance]
	 api_servers = http://controller:9292
	 ```
 
 - Trong section `[oslo_concurrency]` khai báo dòng dưới. Do section `[oslo_concurrency]` chưa có nên ta khai báo thêm.
	 ```sh
	 [oslo_concurrency]
	 lock_path = /var/lib/nova/tmp
	 ```

- Khai báo thêm section mới `[neutron]` để `nova` làm việc với `neutron`

	```sh
	[neutron]
	url = http://controller:9696
	auth_url = http://controller:35357
	auth_type = password
	project_domain_name = default
	user_domain_name = default
	region_name = RegionOne
	project_name = service
	username = neutron
	password = Welcome123

	service_metadata_proxy = True
	metadata_proxy_shared_secret = Welcome123
	```

-  Tạo database cho `nova`
	```sh
	su -s /bin/sh -c "nova-manage api_db sync" nova
	su -s /bin/sh -c "nova-manage db sync" nova
	```
	

<a name="5.2.2."> </a> 
#### 5.2.2. Kết thúc bước cài đặt và cấu hình `nova`

- Khởi động lại các dịch vụ của `nova` sau khi cài đặt & cấu hình `nova`
	```sh
	service nova-api restart
	service nova-cert restart
	service nova-consoleauth restart
	service nova-scheduler restart
	service nova-conductor restart
	service nova-novncproxy restart
	```


- Xóa database mặc định của `nova`
	```sh
	rm -f /var/lib/nova/nova.sqlite
	```

- Kiểm tra xem các service của nova hoạt động tốt hay chưa bằng lệnh dưới
	```sh
	openstack compute service list
	```

- Nếu kết quả lệnh trên không giống dưới đây, hãy xem lại các bước cấu hình ở trên.

	```sh
	+----+--------------------+------------+----------+---------+-------+----------------------------+
	| Id | Binary             | Host       | Zone     | Status  | State | Updated At                 |
	+----+--------------------+------------+----------+---------+-------+----------------------------+
	|  1 | nova-consoleauth   | controller | internal | enabled | up    | 2016-03-27T16:19:42.000000 |
	|  2 | nova-scheduler     | controller | internal | enabled | up    | 2016-03-27T16:19:42.000000 |
	|  3 | nova-conductor     | controller | internal | enabled | up    | 2016-03-27T16:19:42.000000 |
	|  5 | nova-cert          | controller | internal | enabled | up    | 2016-03-27T16:19:42.000000 |
	|  6 | nova-osapi_compute | 0.0.0.0    | internal | enabled | down  | None                       |
	|  7 | nova-metadata      | 0.0.0.0    | internal | enabled | down  | None                       |
	+----+--------------------+------------+----------+---------+-------+----------------------------+
	```


<a name="6."> </a> 	
### 6. Cài đặt NEUTRON(Networking service)
***

<a name="6.1."> </a>
### 6.1. Giới thiệu về `neutron`
***
- Đây là bước cài đặt `NEUTRON` trên node Controller
- Có 2 cơ chế cung cấp network cho các máy ảo là:
 - Provider network (không sử dụng L3 agent trong Neutron)
 - Self-service network:
- Trong hướng dẫn này sẽ lựa chọn cơ chế Self-service để viết tài liệu
- Các thành phần của `neutron` bao gồm:
 - neutron-server: 
 - OpenStack Networking plug-ins and agents: 
 - Messaging queue: 
 
-<a name="6.2."> </a>
### 6.2. Cài đặt và cấu hình `neutron`
***

<a name="6.2.1."> </a>
### 6.2.1. Tạo database và endpoint cho neutron.
***

- Tạo database cho neutron
 - Đăng nhập vào `neutron`
	 ```sh
	 mysql -uroot -pWelcome123
	 ```
 
 - Tạo database và phân quyền
	 ```sh
	 CREATE DATABASE neutron;
	 GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'Welcome123';
	 GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'Welcome123';

	 FLUSH PRIVILEGES;
	 exit;
	 ```

- Tạo user, endpoint cho dịch vụ `neutron`
 - Khai báo biến môi trường
	 ```sh
	 source admin-openrc
	 ```

 - Tạo tài khoản tên là `neutron`
	 ```sh
	 openstack user create neutron --domain default --password Welcome123
	 ```

 - Gán role cho tài khoản `neutron`
	 ```sh
	 openstack role add --project service --user neutron admin
	 ```

 - Tạo dịch vụ tên là `neutron`
	 ```sh
	 openstack service create --name neutron --description "OpenStack Networking" network
	 ```
		
 - Tạo endpoint tên cho `neutron`
	 ```sh
	 openstack endpoint create --region RegionOne network public http://controller:9696

	 openstack endpoint create --region RegionOne network internal http://controller:9696

	 openstack endpoint create --region RegionOne network admin http://controller:9696
	 ```
		
- Cài đặt và cấu hình cho dịch vụ `neutron`. Trong hướng dẫn này lựa chọn cơ chế self-service netwok (có sử dụng L3 agent của neutron).

- Cài đặt các thành phần cho `neutron`
	```sh
	apt-get -y install neutron-server neutron-plugin-ml2 \
	neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
	neutron-metadata-agent
	```

- Cấu hình cho dịch vụ `neutron`
 - Sao lưu file cấu hình gốc của `neutron`
	 ```sh
	 cp /etc/neutron/neutron.conf  /etc/neutron/neutron.conf.orig
	 ```

 - Trong section `[database]` comment dòng:
	 ```sh
	 # connection = sqlite:////var/lib/neutron/neutron.sqlite
	 ```
	 
 và thêm dòng dưới

	```sh
	connection = mysql+pymysql://neutron:Welcome123@controller/neutron
	```
 
 - Trong section `[DEFAULT]` khai báo lại hoặc thêm mới các dòng dưới: 
	 ```sh
	 service_plugins = router
	 allow_overlapping_ips = True
	 rpc_backend = rabbit
	 auth_strategy = keystone
	 notify_nova_on_port_status_changes = True
	 notify_nova_on_port_data_changes = True
	 ```

 - Trong section `[oslo_messaging_rabbit]` khai báo hoặc thêm mới các dòng dưới: 
	 ```sh
	 rabbit_host = controller
	 rabbit_userid = openstack
	 rabbit_password = Welcome123
	 ```

 - Trong section `[keystone_authtoken]` khai báo hoặc thêm mới các dòng dưới:
	 ```sh
	 auth_uri = http://controller:5000
	 auth_url = http://controller:35357
	 memcached_servers = controller:11211
	 auth_type = password
	 project_domain_name = default
	 user_domain_name = default
	 project_name = service
	 username = neutron
	 password = Welcome123
	 ```

 - Trong section `[nova]` khai báo mới hoặc thêm các dòng dưới
	 ```sh
	 [nova]
	 auth_url = http://controller:35357
	 auth_type = password
	 project_domain_name = default
	 user_domain_name = default
	 region_name = RegionOne
	 project_name = service
	 username = nova
	 password = Welcome123
	 ```

- Cài đặt và cấu hình plug-in `Modular Layer 2 (ML2)`
- Sao lưu file `/etc/neutron/plugins/ml2/ml2_conf.ini`
	```sh
	cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig
	```

- Sửa file `/etc/neutron/plugins/ml2/ml2_conf.ini`
 - Trong section `[ml2]` khai báo thêm hoặc sửa dòng dưới
	 ```sh
	 type_drivers = flat,vlan,vxlan
	 tenant_network_types = vxlan
	 mechanism_drivers = linuxbridge,l2population
	 extension_drivers = port_security
 	 ```
 
 - Trong section `[ml2_type_flat]` khai báo thêm hoặc sửa thành dòng dưới
	 ```sh
	 flat_networks = provider
	 ```
		
 - Trong section `[ml2_type_vxlan]` khai báo thêm hoặc sửa thành dòng dưới
	 ```sh
	 vni_ranges = 1:1000
	 ```
		
 - Trong section `[securitygroup]` khai báo thêm hoặc sửa thành dòng dưới
	 ```sh
	 enable_ipset = True
	 ```
		
- Cấu hình `linuxbridge`
 - Sao lưu file  `/etc/neutron/plugins/ml2/linuxbridge_agent.ini`
	 ```sh
	 cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini  /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig
	 ```

 - Trong section `[linux_bridge]` khai báo mới hoặc sửa thành dòng
	 ```sh
	 physical_interface_mappings = provider:eth1
	 ```

 - Trong section `[vxlan]` khai báo mới hoặc sửa thành dòng
	 ```sh
	 enable_vxlan = True
	 local_ip = 10.10.10.40
	 l2_population = True
	 ```

 - Trong section `[securitygroup]` khai báo mới hoặc sửa thành dòng
	 ```sh
	 enable_security_group = True
	 firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
	 ```

- Cấu hình `l3-agent`
 - Sao lưu file `/etc/neutron/l3_agent.ini`
	 ```sh
	 cp /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.orig
	 ```

 - Trong section `[DEFAULT]` khai báo mới hoặc sửa thành dòng dưới: 
	 ```sh
	 interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
	 external_network_bridge =
	 ```
	 
- Cấu hình `DHCP Agent`
 - Sao lưu file ` /etc/neutron/dhcp_agent.ini` gốc
	 ```sh
	 cp  /etc/neutron/dhcp_agent.ini  /etc/neutron/dhcp_agent.ini.orig
	 ```

 - Trong section `[DEFAULT]` khai báo mới hoặc sửa thành dòng dưới
	 ```sh
	 interface_driver = neutron.agent.linux.interface.BridgeInterfaceDriver
	 dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
	 enable_isolated_metadata = True
	 ```

- Cấu hình `metadata agent`
 - Sao lưu file `/etc/neutron/metadata_agent.ini` 
	 ```sh
	 cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig
	 ```

 - Trong section `[DEFAULT]` khai báo mới hoặc sửa thành dòng dưới:
	 ```sh
	 nova_metadata_ip = controller
	 metadata_proxy_shared_secret = Welcome123
	 ```
- Kết thúc quá trình cài đặt `neutron` trên `controller` node
 - Đồng bộ database cho `neutron`
	 ```sh
	 su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
	 --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
	 ```
	
 - Khởi động lại `nova-api`
	 ```sh
	 service nova-api restart
	 ```
  
  - Khởi động lại các dịch vụ của `neutron`
	 ```sh
	 service neutron-server restart
	 service neutron-linuxbridge-agent restart
	 service neutron-dhcp-agent restart
	 service neutron-metadata-agent restart
	 service neutron-l3-agent restart
	 ```
		
 - Xóa database mặc định của `neutron`
	 ```sh
	 rm -f /var/lib/neutron/neutron.sqlite
	 ```
	 
 - Kiểm tra lại hoạt động của các dịch vụ trong `neutron`
		```sh
		root@controller:~# neutron agent-list
		+--------------------------------------+--------------------+------------+-------------------+-------+----------------+---------------------------+
		| id                                   | agent_type         | host       | availability_zone | alive | admin_state_up | binary                    |
		+--------------------------------------+--------------------+------------+-------------------+-------+----------------+---------------------------+
		| 0da48098-4f27-46e4-ac91-f2c636814559 | Metadata agent     | controller |                   | :-)   | True           | neutron-metadata-agent    |
		| 384da2b3-4c14-4436-9c2f-73396499bdbd | DHCP agent         | controller | nova              | :-)   | True           | neutron-dhcp-agent        |
		| 5f6cc6b1-7789-4eab-afcb-27186aec44c6 | Linux bridge agent | controller |                   | :-)   | True           | neutron-linuxbridge-agent |
		| e6d2fa51-ff09-44f9-a510-72817f17fb31 | L3 agent           | controller | nova              | :-)   | True           | neutron-l3-agent          |
		+--------------------------------------+--------------------+------------+-------------------+-------+----------------+---------------------------+
		````


<a name="7."> </a> 	
### 7. Cài đặt HORIZON (dashboad)
***
- HORIZON hay còn gọi là dashboad - cung cấp giao diện trên web để người dùng có thể sử dụng OpenStack

<a name="7.1."> </a> 	
#### 7.1. Cài đặt và cấu hình HORIZON (dashboad)
***

- Cài đặt các thành phần cho dashboad
	```sh
	apt-get -y install openstack-dashboard
	```

- Sao lưu lại file cấu hình cho dashboad 

```sh
cp /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.orig
```

- Tìm các dòng sau trong file ` /etc/openstack-dashboard/local_settings.py` và chỉnh sửa như bên dưới

```sh
OPENSTACK_HOST = "controller"
```

```sh
ALLOWED_HOSTS = ['*', ]
```

```

CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}
```
 
```sh
OPENSTACK_KEYSTONE_URL = "http://%s:5000/v3" % OPENSTACK_HOST
```



```sh
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 2,
}
```

```sh
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "default"
```

```sh
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
```

```sh
TIME_ZONE = "asia/Ho_Chi_Minh"
```

- Xóa theme mặc định của ubuntu
```sh
apt-get -y remove --auto-remove openstack-dashboard-ubuntu-theme
```

- Khởi động lại apache
```sh
service apache2 restart
```

- Mở web với địa chỉ  http://172.16.69.40/horizon để vào dashboad
	 
	 
	 
<a name="8."> </a> 		 
## 8. Cài đặt trên node compute
***
<a name="8.1."> </a> 	
### 8.1. Bước chuẩn bị
***
<a name="8.1.1."> </a> 	
#### 8.1.1.Thiết lập hostname
- Sửa file `/etc/hosts` với nội dung như bên dưới
	```sh
	127.0.0.1       localhost compute1
	10.10.10.41     compute1
	10.10.10.40     controller
	```


- Sửa file /etc/hostname
	```sh
	compute1
	```
	
<a name="8.1.2."> </a> 	
#### 8.1.2. Thiết lập về network
- Dùng vi mở file `/etc/network/interfaces` và thiết lập như dưới
	```sh
	# This file describes the network interfaces available on your system
	# and how to activate them. For more information, see interfaces(5).

	# The loopback network interface
	auto lo
	iface lo inet loopback

	# NIC MGNT
	auto eth0
	iface eth0 inet static
	address 10.10.10.41
	netmask 255.255.255.0

	# NIC EXT
	auto eth1
	iface eth1 inet static
	address 172.16.69.41
	netmask 255.255.255.0
	gateway 172.16.69.1
	dns-nameservers 8.8.8.8
	```

- Khởi động lại network và đăng nhập lại với quyền root
	```sh
	ifdown -a && ifup -a
	```

- Đăng nhập với quyền `root` và kiểm tra kết nối
```sh

KẾT QUẢ PING

```

<a name="8.1.3."> </a> 	
#### 8.1.3. Cài đặt các gói phần mềm bổ trợ
- Cài đặt và cấu hình NTP trên Compute node
 - Cài đặt NTP Client
	 ```sh
	 apt-get -y install chrony
	 ```

 - Sao lưu file `/etc/chrony/chrony.conf`
	 ```sh
	 cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.orig
	 ```

- Chỉnh sửa file `/etc/chrony/chrony.conf`.
 - Thay các dòng dưới
 
	 ```sh
	 server 0.debian.pool.ntp.org offline minpoll 8
	 server 1.debian.pool.ntp.org offline minpoll 8
	 server 2.debian.pool.ntp.org offline minpoll 8
	 server 3.debian.pool.ntp.org offline minpoll 8
	 ```
		
 bằng dòng
 
	```sh
	server controller iburst
	```

 - Khởi động lại dịch vụ NTP
	 ```sh
	 service chrony restart
	 ```

 - Kiểm chứng lại xem NTP đã cài đặt thành công và đồng bộ được thời gian hay chưa
	 ```sh
	 chronyc sources
	 ```
 
 - Kết quả của lệnh trên làm
		```sh
		root@compute1:/etc/chrony# chronyc sources
		210 Number of sources = 1
		MS Name/IP address         Stratum Poll Reach LastRx Last sample
		===============================================================================
		^? controller                    3   6     3     1    -25ms[  -25ms] +/-  129ms
		root@compute1:/etc/chrony#
		```

- Cài đặt gói để tải các bộ cài cho bản OpenStack Mitaka
	```sh
	apt-get -y install software-properties-common
	add-apt-repository -y cloud-archive:mitaka
	```

- Cập nhật các gói phần mềm và khởi động lại máy.
	```sh
	apt-get -y update && apt-get -y dist-upgrade && init 6
	```

- Đăng nhập với quyền root và cài đặt các gói client cho node Compute
	```sh
	apt-get -y install python-openstackclient
	```

<a name="9."> </a> 
### 9. Cài đặt NOVA trên node compute
***
- Cài đặt gói nova-compute
```sh
apt-get -y install nova-compute
```

- Cấu hình nova
 - Sao lưu file `/etc/nova/nova.conf` 
 ```sh
 cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
 ```
 
 - Trong section `[DEFAULT]` khai báo các dòng sau
	 ```sh
	 rpc_backend = rabbit
	 auth_strategy = keystone
	 my_ip = 10.10.10.41

	 use_neutron = True
	 firewall_driver = nova.virt.firewall.NoopFirewallDriver
 	 ```
 
 - Khai báo thêm section `[oslo_messaging_rabbit]` và các dòng dưới
	 ```sh
	 [oslo_messaging_rabbit]
	 rabbit_host = controller
	 rabbit_userid = openstack
	 rabbit_password = Welcome123
	 ```

 - Khai báo thêm section `[keystone_authtoken]` và các dòng dưới
	 ```sh
	 [keystone_authtoken]
	 auth_uri = http://controller:5000
	 auth_url = http://controller:35357
	 memcached_servers = controller:11211
	 auth_type = password
	 project_domain_name = default
	 user_domain_name = default
	 project_name = service
	 username = nova
	 password = Welcome123
	 ```

 - Khai báo thêm section `[vnc]` và các dòng dưới.
	 ```sh
	 [vnc]
	 enabled = True
	 vncserver_listen = 0.0.0.0
	 vncserver_proxyclient_address = $my_ip
	 novncproxy_base_url = http://172.16.69.40:6080/vnc_auto.html
	 ```

 - Khai báo thêm section `[glance]` và các dòng dưới
	 ```sh
	 [glance]
	 api_servers = http://controller:9292
	 ```

 - Khai báo thêm section `[oslo_concurrency]` và các dòng dưới.
	 ```sh
	 [oslo_concurrency]
	 lock_path = /var/lib/nova/tmp
	 ```
		
 - Khai báo thêm section `[neutron]` và các dòng dưới.
	 ```sh
	 [neutron]
	 url = http://controller:9696
	 auth_url = http://controller:35357
	 auth_type = password
	 project_domain_name = default
	 user_domain_name = default
	 region_name = RegionOne
	 project_name = service
	 username = neutron
	 password = Welcome123
	 ```

- Khởi động lại dịch vụ `nova-compute`
	```sh
	service nova-compute restart
	```

- Xóa database mặc định của hệ thống tạo ra
	```sh
	rm -f /var/lib/nova/nova.sqlite
	```

- Dùng  lệnh `vi admin-openrc` chứa nội dung dưới
	```sh
	export OS_PROJECT_DOMAIN_NAME=default
	export OS_USER_DOMAIN_NAME=default
	export OS_PROJECT_NAME=admin
	export OS_USERNAME=admin
	export OS_PASSWORD=Welcome123
	export OS_AUTH_URL=http://controller:35357/v3
	export OS_IDENTITY_API_VERSION=3
	export OS_IMAGE_API_VERSION=2
	```

- Thực thi file `admin-openrc`
	```sh
	source admin-openrc
	```


- Kiểm tra lại các dịch vụ của `nova` đã được cài đặt thành công hay chưa
	```sh
	openstack compute service list
	```
	
- Kết quả sẽ hiển thị như bên dưới.
	```sh
	root@compute1:~# openstack compute service list
	+----+------------------+------------+----------+---------+-------+----------------------------+
	| Id | Binary           | Host       | Zone     | Status  | State | Updated At                 |
	+----+------------------+------------+----------+---------+-------+----------------------------+
	|  3 | nova-cert        | controller | internal | enabled | up    | 2016-04-15T15:10:30.000000 |
	|  4 | nova-consoleauth | controller | internal | enabled | up    | 2016-04-15T15:10:30.000000 |
	|  5 | nova-scheduler   | controller | internal | enabled | up    | 2016-04-15T15:10:31.000000 |
	|  6 | nova-conductor   | controller | internal | enabled | up    | 2016-04-15T15:10:32.000000 |
	|  7 | nova-compute     | compute1   | nova     | enabled | up    | 2016-04-15T15:10:25.000000 |
	+----+------------------+------------+----------+---------+-------+----------------------------+
	root@compute1:~#
	```
	
<a name="10."> </a> 
### 10. Cài đặt và cấu hình `NEUTRON` trên node compute
***

- Cài đặt các gói
	```sh
	apt-get -y install neutron-linuxbridge-agent
	```

- Cấu hình `NEUTRON`

 - Sao lưu file `/etc/neutron/neutron.conf` gốc
	 ```sh
	 cp /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig
	 ```
	 
- Sửa file `/etc/neutron/neutron.conf`

 - Trong section `[DEFAULT]` khai báo hoặc chỉnh sửa các dòng sau
	 ```sh
	 rpc_backend = rabbit
	 auth_strategy = keystone
	 ```
 
 - Trong section `[oslo_messaging_rabbit]` khai báo hoặc chỉnh sửa các dòng sau
	 ```sh
	 rabbit_host = controller
	 rabbit_userid = openstack
	 rabbit_password = Welcome123
	 ```
	
 - Trong section `[keystone_authtoken]` khai báo hoặc chỉnh sửa các dòng sau
	 ```sh
	 auth_uri = http://controller:5000
	 auth_url = http://controller:35357
	 memcached_servers = controller:11211
	 auth_type = password
	 project_domain_name = default
	 user_domain_name = default
	 project_name = service
	 username = neutron
	 password = Welcome123
	 ```
		
- Cấu hình  Linux bridge trên node compute
 - Sao lưu file `/etc/neutron/plugins/ml2/linuxbridge_agent.ini`
 ```sh
 cp /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.orig
 ```
 
 - Trong section `[linux_bridge]` khai báo dòng dưới.
	 ```sh
	 [linux_bridge]
	 # eth1 là card EXT
	 physical_interface_mappings = provider:eth1
	 ```

 - Trong section [vxlan] khai báo dòng dưới.
	 ```sh
	 [vxlan]
	 enable_vxlan = True
	 local_ip = 10.10.10.41
	 l2_population = True
	 ```

 - Trong section `[securitygroup]` khai báo dòng dưới.
	 ```sh
	 [securitygroup]
	 enable_security_group = True
	 firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
	 ```

 - Khởi động lại Linux bridge agent:
	 ```sh
	 service neutron-linuxbridge-agent restart
	 ```
 
- Thực thi file `admin-openrc` để khai báo biến môi trường
	```sh
	source admin-openrc
	```

- Kiểm tra dịch vụ của `neutron`
	```sh
	neutron agent-list
	```

- Kết thúc bước cài đặt Neutron trên compute node. Tới đây đã có thể bắt đầu tạo máy ảo.


# CÀI ĐẶT NÂNG CAO
***

# CÀI ĐẶT ỨNG DỤNG THU THẬP LOG
***

# HƯỚNG DẪN SỬ DỤNG DASHBOAD
***

After install COMPUTE NODE, move to step that guide to use dashboard


## Using dashboard to initialize network, VM, rules.

- Login to dasboard
![mitaka-horizon1.png](./images/mitaka-horizon1.png)

- Select tab `admin => Access & Security => Manage Rules`
![mitaka-horizon2.png](./images/mitaka-horizon2.png)

- Select tab `Add Rule`
![mitaka-horizon3.png](./images/mitaka-horizon3.png)

- Open all rule from outside to virtual machine
![mitaka-horizon4.png](./images/mitaka-horizon4.png)


### Initialize network
#### Initialize external network range
- Select tab `Admin => Networks => Create Network`
![mitaka-net-ext1.png](./images/mitaka-net-ext1.png)

- Enter and select tabs like picture below.
![mitaka-net-ext2.png](./images/mitaka-net-ext2.png)
```sh
Name: provider
Project: admin
Provider Network Typy: Flat
Physical Network: provider
Admin State: UP
Shared: check
External Network: check
```

- Click to newly created `ext-net` to declare subnet for external range.
![mitaka-net-ext3.png](./images/mitaka-net-ext3.png)

- Select tab `Creat Subnet`
![mitaka-net-ext4.png](./images/mitaka-net-ext4.png)

- Declare IP range of subnet for external range
![mitaka-net-ext5.png](./images/mitaka-net-ext5.png)

- Declare pools and DNS
![mitaka-net-ext6.png](./images/mitaka-net-ext6.png)

#### Initialize internal network range
- Select tabs in turn of rank : "admin => Project => Network => Networks => Create Network"
![mitaka-net-int1.png](./images/mitaka-net-int1.png)

- Declare name for internal network
![mitaka-net-int2.png](./images/mitaka-net-int2.png)

- Declare subnet for internal network
![mitaka-net-int3.png](./images/mitaka-net-int3.png)

- Declare IP range for Internal network
![mitaka-net-int4.png](./images/mitaka-net-int4.png)

#### Initialize Router for project admin
- Select by tabs "admin => Project => Network => Routers => Create Router"
![mitaka-r1.png](./images/mitaka-r1.png)

- Initialize router name and select like picture below
![mitaka-r2.png](./images/mitaka-r2.png)

- Apply interface for router
![mitaka-r3.png](./images/mitaka-r3.png)

![mitaka-r4.png](./images/mitaka-r4.png)

![mitaka-r5.png](./images/mitaka-r5.png)
- ending of initializing steps:  exteral network, internal network, router


## Initialize virtual machine (Instance)
- Project admin => Instances => Launch Instance"
![mitaka-instance1.png](./images/mitaka-instance1.png)

![mitaka-instance2.png](./images/mitaka-instance2.png)

![mitaka-instance3.png](./images/mitaka-instance3.png)

![mitaka-instance4.png](./images/mitaka-instance4.png)

![mitaka-instance5.png](./images/mitaka-instance5.png)

![mitaka-instance6.png](./images/mitaka-instance6.png)

![mitaka-instance7.png](./images/mitaka-instance7.png)

![mitaka-instance8.png](./images/mitaka-instance8.png)

![mitaka-instance9.png](./images/mitaka-instance9.png)

![mitaka-instance10.png](./images/mitaka-instance10.png)


## Check virtual machine (Instance)

![mitaka-instance11.png](./images/mitaka-instance11.png)

![mitaka-instance12.png](./images/mitaka-instance12.png)

![mitaka-instance13.png](./images/mitaka-instance13.png)
- Nhập mật khẩu với thông tin dưới
```sh
user: cirros
password: cubswin:)
```
