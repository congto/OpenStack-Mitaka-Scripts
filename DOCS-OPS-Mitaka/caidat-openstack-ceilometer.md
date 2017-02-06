## Cài đặt MongoDB

### Thực hiện trên CONTROLLER NODE

- Tải gói

```sh
apt-get update

apt-get -y install mongodb-server mongodb-clients python-pymongo
```

- Sửa file `/etc/mongodb.conf` với các dòng sau

```sh
bind_ip = 0.0.0.0
smallfiles = true
```

- Khởi động lại MongoDB

```sh
service mongodb stop
rm /var/lib/mongodb/journal/prealloc.*
service mongodb start
```

- Tạo DB

```sh
mongo --host 10.10.10.140 --eval '
  db = db.getSiblingDB("ceilometer");
  db.addUser({user: "ceilometer",
  pwd: "Welcome123",
  roles: [ "readWrite", "dbAdmin" ]})'
```

- Khai báo endpoint

```sh
openstack user create ceilometer --domain default --password Welcome123 

openstack role add --project service --user ceilometer admin

openstack service create --name ceilometer --description "Telemetry" metering

openstack endpoint create --region RegionOne metering public http://10.10.10.140:8777

openstack endpoint create --region RegionOne metering internal http://10.10.10.140:8777

openstack endpoint create --region RegionOne metering admin http://10.10.10.140:8777
```

-Cài đặt các gói ceilometer

```sh
apt-get -y install ceilometer-api ceilometer-collector \
  ceilometer-agent-central ceilometer-agent-notification
  python-ceilometerclient
```

#### Cấu hình ceilometer

- Sửa file `/etc/ceilometer/ceilometer.conf`, tìm các dòng tương ứng hoặc bổ sung dòng mới với các thông số như sau

```sh
cp /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.orig
```

- Ở section `[database]`

```sh
[database]
connection = mongodb://ceilometer:Welcome123@10.10.10.140:27017/ceilometer
```

- Ở section `[DEFAULT]`

```sh
[DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone
```

- Ở section `[oslo_messaging_rabbit]`

```sh
[oslo_messaging_rabbit]
rabbit_host = 10.10.10.140
rabbit_userid = openstack
rabbit_password = Welcome123
```

- Ở section `[keystone_authtoken]`

```sh
[keystone_authtoken]
auth_uri = http://10.10.10.140:5000
auth_url = http://10.10.10.140:35357
memcached_servers = 10.10.10.140:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = ceilometer
password = Welcome123
```

- Ở section `[service_credentials]`

```sh
[service_credentials]
auth_type = password
auth_url = http://10.10.10.140:5000/v3
project_domain_name = default
user_domain_name = default
project_name = service
username = ceilometer
password = Welcome123
interface = internalURL
region_name = RegionOne
```

- Khởi động lại các dịch vụ của ceilometer

```sh
service ceilometer-agent-central restart
service ceilometer-agent-notification restart
service ceilometer-api restart
service ceilometer-collector restart
```

#### Cấu hình ceilometer đối với Glance

- Sửa file `/etc/glance/glance-api.conf` và file `/etc/glance/glance-api.conf` với các cấu hình dưới. LƯU Ý RẰNG SẼ PHẢI SỬA Ở CẢ 2 FILE

- Ở section `[DEFAULT]`

```sh
[DEFAULT]
rpc_backend = rabbit
```

- Ở section `[oslo_messaging_notifications]`

```sh
[oslo_messaging_notifications]
driver = messagingv2
```

- Ở section `[oslo_messaging_rabbit]`

```sh
[oslo_messaging_rabbit]
rabbit_host = 10.10.10.140
rabbit_userid = openstack
rabbit_password = Welcome123
```

- Khởi động lại dịch vụ Glance

```sh
service glance-registry restart
service glance-api restart
```

### Thực hiện trên COMPUTE NODE

### Cài đặt gói ceilomêtr cho compute node

- Cài đặt gói ceilomêtr cho compute node

```sh
apt-get update
apt-get -y install ceilometer-agent-compute
```

#### Khai báo cấu hình 

- Sửa file /etc/ceilometer/ceilometer.conf như sau:

```
cp /etc/ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf.orig
```

- Ở section `[DEFAULT]`

```sh
[DEFAULT]
rpc_backend = rabbit
auth_strategy = keystone

```

- Ở section `[oslo_messaging_rabbit]`

```sh
[oslo_messaging_rabbit]
rabbit_host = 10.10.10.140
rabbit_userid = openstack
rabbit_password = Welcome123
```

- Ở section `[keystone_authtoken]`

```sh
[keystone_authtoken]
auth_uri = http://10.10.10.140:5000
auth_url = http://10.10.10.140:35357
memcached_servers = 10.10.10.140:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = ceilometer
password = Welcome123
```

- Ở section `[service_credentials]`

```sh
[service_credentials]
auth_type = password
auth_url = http://10.10.10.140:5000/v3
project_domain_name = default
user_domain_name = default
project_name = service
username = ceilometer
password = Welcome123
interface = internalURL
region_name = RegionOne
```

- Sửa file `/etc/nova/nova.conf`, ở section `[DEFAULT]` như sau:

```sh
[DEFAULT]
instance_usage_audit = True
instance_usage_audit_period = hour
notify_on_state_change = vm_and_task_state
notification_driver = messagingv2
```

#### Khởi động lại các dịch vụ cần thiết

- ceilometer agent

```sh
service ceilometer-agent-compute restart
```

- Compute service

```sh
service nova-compute restart
```


### Kiểm tra dịch vụ

- Kiểm tra meter 

```sh
ceilometer meter-list
```