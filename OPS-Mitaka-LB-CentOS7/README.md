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


## Tạo máy ảo bằng lệnh
- Các bước tạo máy ảo bằng lệnh:

 - Kiểm tra danh flavor (các gói cấu hình) `openstack flavor list`
    ```sh
    [root@controller scripts]# openstack flavor list
    +----+-----------+-------+------+-----------+-------+-----------+
    | ID | Name      |   RAM | Disk | Ephemeral | VCPUs | Is Public |
    +----+-----------+-------+------+-----------+-------+-----------+
    | 1  | m1.tiny   |   512 |    1 |         0 |     1 | True      |
    | 2  | m1.small  |  2048 |   20 |         0 |     1 | True      |
    | 3  | m1.medium |  4096 |   40 |         0 |     2 | True      |
    | 4  | m1.large  |  8192 |   80 |         0 |     4 | True      |
    | 5  | m1.xlarge | 16384 |  160 |         0 |     8 | True      |
    +----+-----------+-------+------+-----------+-------+-----------+
    ```
    
 - Kiểm tra danh sách các image `openstack image list`
    ```sh
    [root@controller scripts]# openstack image list
    +--------------------------------------+--------+--------+
    | ID                                   | Name   | Status |
    +--------------------------------------+--------+--------+
    | 1552b75b-4889-4a45-8a58-6890e6eaee76 | cirros | active |
    +--------------------------------------+--------+--------+
    ```

 - Kiểm tra danh sách các network `openstack network list`
    ```sh
    [root@controller scripts]# openstack network list
    +--------------------------------------+-------------+--------------------------------------+
    | ID                                   | Name        | Subnets                              |
    +--------------------------------------+-------------+--------------------------------------+
    | d04caf30-a89c-4684-b9ea-dff71524d8cd | ext-net     | 441c56e0-116f-4539-bdbb-8f6657ec5170 |
    | 473d83c7-beda-4eed-bf83-eede19e7bdd8 | selfservice | 7e663ccc-d73d-4f06-bedf-7bb1e508ad0a |
    +--------------------------------------+-------------+--------------------------------------+
    ````
    
 - Gán biến bằng ID của dải mạng `selfservice`
    ```sh
    selfservice=`openstack network list | awk '/selfservice/ {print $2}'`
    ```
    
 - Tạo máy ảo với image là `cirros`, flavor `m1.tiny`, gắn vào dải mạng `selfservice`, thuộc security group `default` và có tên là `vm6969`
    ```sh
    openstack server create --flavor m1.tiny --image cirros \
        --nic net-id=$selfservice --security-group default vm6969
    ```


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
 
 - Liệt kê các router
 ```sh
 neutron router-list
 ```
 
 - Kiểm tra các port trên router có tên là `admin-router`
 ```sh
 neutron router-port-list admin-router
 ```
