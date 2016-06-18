# Các bước thực hiện

## Mô trường thực hiện
- OpenStack Mitaka
- Node Controller
 - OS: CENTOS 7.x or RHEL 7.x
 - NIC: 
  - eth0 : 
    - IP address: 10.10.10.40
    - Subnet mask: 255.255.255.0
  - eth1 : 
   - IP addres: 172.16.69.40
   - Subnet mask: 255.255.255.0
   - Gateway: 172.16.69.1
   - DNS-NameServer: 8.8.8.8.
  - HDD: 80GB
  - RAM: 4GB
  - CPU: 1
  
- Node Compute
 - OS: CENTOS 7.x or RHEL 7.x
 - NIC: 
  - eth0 : 
   - IP address: 10.10.10.41
   - Subnet mask: 255.255.255.0
  - eth1 : 
   - IP addres: 172.16.69.41
   - Subnet mask: 255.255.255.0
   - Gateway: 172.16.69.1
   - DNS-NameServer: 8.8.8.8.
  - HDD: 80GB
  - RAM: 4GB
  - CPU: 2


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


## Chú ý: 

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
