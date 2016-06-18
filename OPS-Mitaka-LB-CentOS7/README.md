# Các bước thực hiện

## Mô trường thực hiện
- OpenStack Mitaka
- Node Controller
 - OS: `CENTOS 7.x` or `RHEL 7.x`
 - NIC: 
    - eth0 : 10.10.10.40/24
    - eth1 : `172.16.69.40/24`, Gateway: `172.16.69.1`,  DNS `8.8.8.8`
   - HDD: `80GB`, RAM: `4GB`, CPU: `1`
  
- Node Compute
 - OS: `CENTOS 7.x` or `RHEL 7.x`
 - NIC: 
    - eth0 : 10.10.10.41/24
    - eth1 : `172.16.69.41/24`, Gateway: `172.16.69.1`,  DNS `8.8.8.8`
   - HDD: `80GB`, RAM: `4GB`, CPU: `1`

   
## CONTROLLER
- Chuẩn bị cài đặt
```sh
yum -y update && yum -y install git

git clone https://github.com/congto/OpenStack-Mitaka-Scripts.git
mv /root/OpenStack-Mitaka-Scripts/OPS-Mitaka-LB-CentOS7/scripts /root
rm -rf /root/OpenStack-Mitaka-Scripts
cd scripts/
chmod +x *.sh
```
- Setup environment on file `config.cfg` if you need.

- Setup IP
```sh
bash ctl-1-ipadd.sh
```

- Login server with account `root` 
- Prepare 
```sh
cd /scripts
bash ctl-2-prepare.sh
```

- Install keystone
```sh
bash ctl-3.keystone.sh
```

- Load  environment variables
```sh
source admin-openrc
```

- Install Glance
```sh
bash ctl-4-glance.sh
```

- Install Nova
```sh
bash  ctl-5-nova.sh
```

- Install Neutron
```sh
bash ctl-6-neutron.sh
```

- Install Horizon
```sh
bash ......
```

- Moving COMPUTE NODE

## COMPUTE
- Clone git or scp from Controller node
```sh
yum -y update && yum -y install git

git clone https://github.com/congto/OpenStack-Mitaka-Scripts.git
mv /root/OpenStack-Mitaka-Scripts/OPS-Mitaka-LB-CentOS7/scripts /root
rm -rf /root/OpenStack-Mitaka-Scripts
cd scripts/
chmod +x *.sh
```
- Setup environment on file `config.cfg` if you need. Variables the same `controller node`

- Setup IP
```sh
bash com1-ipdd.sh
```

- Install nova, neutron on COMPUTE node
```sh
bash com1-prepare.sh
```

- Moving Controller node for install Horizon



###  Chú ý: 

- Đăng ký để cài đặt với RHEL
```sh
subscription-manager register --username dia_chi_email --password mat_khau --auto-attach
```

- Kiểm tra phiên bản CENTOS
```sh
[root@ctl-cent7 scripts]# cat /etc/redhat-release
CentOS Linux release 7.2.1511 (Core)
[root@ctl-cent7 scripts]#
```

- Các lệnh trong neutron

 - Kiểm tra danh sách network
 ```sh
 openstack network list
 ```
 
 - Kiểm tra các port trên router có tên là `admin-router`
 ```sh
 neutron router-port-list admin-router
 ```
