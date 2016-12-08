# Installation Steps

### Prepare LAB enviroment
- Using in VMware Workstation or Virtualbox ... enviroment

#### Configure CONTROLLER NODE
```sh
OS: Ubuntu Server 14.04 64 bit
RAM: 4GB
CPU: 2x2,  VT supported
NIC1: eth0: 10.10.10.0/24 (interntel range, using vmnet or hostonly in VMware Workstation)
NIC2: eth1: 172.16.69.0/24, gateway 172.16.69.1 (external range - using NAT or Bridge VMware Workstation)
HDD: +60GB
```


#### Configure COMPUTE NODE
```sh
OS: Ubuntu Server 14.04 64 bit
RAM: 4GB
CPU: 2x2, VT supported
NIC1: eth0: 10.10.10.0/24 (interntel range, using vmnet or hostonly in VMware Workstation)
NIC2: eth1: 172.16.69.0/24, gateway 172.16.69.1 (external range - using NAT or Bridge VMware Workstation  )
HDD: +100GB
```

## Mô hình 2 node 
![Mitaka-topo-2node.png](./images/Mitaka-topo-2node.png)

### Execute script
- Install git package and dowload script 
```sh
su -
apt-get update
apt-get -y install git 

git clone https://github.com/congto/OpenStack-Mitaka-Scripts.git
mv /root/OpenStack-Mitaka-Scripts/OPS-Mitaka-OVS-Ubuntu/scripts/ /root/
rm -rf OpenStack-Mitaka-Scripts/
cd scripts/
chmod +x *.sh
```

## Install on CONTROLLER NODE
### install IP establishment script and repos for mitaka
- Edit file `config.cfg` in dicrectory with IP that you want to use.
 
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

### Install Cinder
- Lưu ý: chỉ chọn một trong 2 lựa chọn dưới đây
- `Lựa chọn 1`: Không tách node cinder thành một máy chủ riêng:
 - Nếu cài `cinder-volume` cùng node compute thì thực hiện sau sau, lưu ý máy controller cần có ổ cứng `/dev/vdb`.
 
      ```sh
      ctl-7-cinder-aio.sh
      ```
- `Lựa chọn 2`: Tách node cinder ra một máy chủ riêng
 - Với mô hình tách node cinder (cài thành phần `cinder-volume`) thì thực hiện script.
 
      ```sh
      ctl-7-cinder.sh
      ```
 - Lúc này cần thực hiện các bước tiếp theo trên máy chủ `Cinder`


### Install NEUTRON
```sh
bash ctl-6-neutron.sh
```
- After NEUTRON installation done, controller node will restart.
- Login with `root` end execute Horizon installation script.

### Install HORIZON
- Login with  `root` privilege and execute script below
```sh
bash ctl-horizon.sh
```

## Install on COMPUTE NODE
### Dowload GIT and script
- install git package and dowload script 
```sh
su -
apt-get update
apt-get -y install git 

git clone https://github.com/congto/OpenStack-Mitaka-Scripts.git
mv /root/OpenStack-Mitaka-Scripts/OPS-Mitaka-OVS-Ubuntu/scripts/ /root/
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
com1-2-ovs.sh
```

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

- Click to newly created `provider` to declare subnet for external range.
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

![mitaka-instance13.png](./images/mitaka-instance13.png)

![mitaka-instance13.png](./images/mitaka-instance13.png)
- Nhập mật khẩu với thông tin dưới
```sh
user: cirros
password: cubsin:)
```



