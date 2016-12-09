# Các bước cài đặt

### Môi trường LAB
- Using in VMware Workstation or Virtualbox ... enviroment
- Thiết lập Network trong VMware Workstation
- Ubuntu 14.04 64 Bit

### Thành phần OpenStack sử dụng

OpenStack Mitaka 

- Keystone
- Glance
- Nova
- Neutron
 - OpenvSwitch
 - Provider Network: Sử dụng use case VLAN (cấp máy ảo theo các VLAN của mạng bên ngoài)
- Horizon 


#### Yêu cầu về các máy chủ (Số lượng card mạng, ổ cứng, dải IP )

```sh
- bổ sung vào đây sớm 
```

## Mô hình 2 node 
![Mitaka-topo-2node.png](./images/OPS-Network-TOPO-Provider-VLAN.png)

### Execute script
- Install git package and dowload script 
```sh
su -
apt-get update
apt-get -y install git 

git clone -b vlan https://github.com/congto/OpenStack-Mitaka-Scripts.git
mv /root/OpenStack-Mitaka-Scripts/Ubuntu-OVS-VLAN/scripts/ /root/
rm -rf OpenStack-Mitaka-Scripts/
cd scripts/
chmod +x *.sh
```

## Cài đặt trên máy CONTROLLER 
### Thực hiện script cấu hình IP, cài các gói cơ bản.
- Sửa file `config.cfg` nếu cần thay đổi IP và mật khẩu. Nếu ko thay đổi, các máy sẽ lấy IP, mật khẩu ... trong file cấu hình mẫu
 
```sh
bash ctl-1-ipadd.sh
```

### Install NTP, MariaDB packages
```sh
bash ctl-2-prepare.sh
```

### Install KEYSTONE
- Install Keystone
```sh
bash ctl-3.keystone.sh
```

- Declare enviroment parameter
```sh
source admin-openrc
```

### Install GLANCE
```sh
bash ctl-4-glance.sh
```

### Install NOVA
```sh
bash ctl-5-nova.sh
```




### Install NEUTRON
```sh
bash ctl-6-neutron-OVS-provider-VLAN.sh
```
- After NEUTRON installation done, controller node will restart.
- Login with `root` end execute Horizon installation script.

### Install HORIZON
- Login with  `root` privilege and execute script below
```sh
bash ctl-horizon.sh
```

- Ghi lại địa chỉ IP, tài khoản, mật khẩu để sau khi cài xong máy compute sẽ sử dụng.

## Install on COMPUTE NODE
### Dowload GIT and script
- install git package and dowload script 
```sh
su -
apt-get update
apt-get -y install git 

git clone -b vlan https://github.com/congto/OpenStack-Mitaka-Scripts.git
mv /root/OpenStack-Mitaka-Scripts/Ubuntu-OVS-VLAN/scripts/ /root/
rm -rf OpenStack-Mitaka-Scripts/
cd scripts/
chmod +x *.sh
```

### Establish IP and hostname
- Edit file `config.cfg`  to make it suitable with your IP.
- Execute script to establish IP, hostname
```sh
bash com1-1-ipdd.sh
```
- The server will restart after script `com1-ipdd.sh` is executed.
- Login to server with root privilege and execute conponents installation script on Nova

```sh
su -
cd scripts/
bash com1-2-osv-provider-VLAN.sh
```

After install COMPUTE NODE, move to step that guide to use dashboard


## Thực thi script tạo VM
- Login vào máy CTL và thự hiện các lệnh sau

```sh
su -
cd scripts
source admin-openrc

bash ctl-create-network.sh
```

## Sử dụng dashboad

- Truy cập vào dashboad với Link, user và password đã được tạo trước đó.

