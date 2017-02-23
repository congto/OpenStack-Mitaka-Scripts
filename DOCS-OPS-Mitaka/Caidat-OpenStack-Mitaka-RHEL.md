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
![OpenStack Mitaka Topo](/DOCS-OPS-Mitaka/images/openstack-mitaka-network-layout-rhel.png)

<a name="1.2"> </a> 
### 1.2 Các tham số phần cứng đối với các node
![OpenStack Mitaka Topo](/DOCS-OPS-Mitaka/images/Mitaka-ip-hardware.png)

## Mô hình 2 node 
![Mitaka-topo-2node.png](./images/openstack-mitaka-network-layout-rhel.png)

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
#### 2.1.1 Thiết lập các thành phần cơ bản

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

### Khai báo repos cho OpenStack Mitaka

- Tải gói

```sh
yum install https://repos.fedorapeople.org/repos/openstack/openstack-mitaka/rdo-release-mitaka-6.noarch.rpm
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

