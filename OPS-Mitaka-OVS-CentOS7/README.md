# Các bước thực hiện
# MỤC LỤC
[1. Mô trường thực hiện](#moitruongthuchien)

[2. Cài đặt trên Controller](#controller)

[3. Cài đặt trên Compute](#compute)

[4. Tạo máy ảo bằng lệnh](#taomayaobanglenh)

[5. Các ghi chú khác](#ghichukhac)


<a name="moitruongthuchien"></a>
## Môi trường thực hiện

- Cấu hình yêu cầu đối với các máy và IP Planning
![](http://image.prntscr.com/image/7d37b7eb7453415ea414682268cdfeb4.png)

- Mô hình cài đặt
![](http://image.prntscr.com/image/1eeb23aed22b48fe84965c95c2338399.png)

<a name="controller"></a>
## CONTROLLER
- Chuẩn bị cài đặt trên node Controller
    ```sh
    yum -y update && yum -y install git

    git clone https://github.com/congto/OpenStack-Mitaka-Scripts.git
    mv /root/OpenStack-Mitaka-Scripts/OPS-Mitaka-OVS-CentOS7/scripts /root
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

<a name="compute"></a>
## COMPUTE
- Thực hiện cài đặt trên node compute
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


<a name=taomayaobanglenh></a>
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
 
 - Cấp phát IP của dải `ext-net` cho máy ảo
    ```sh
    [root@controller scripts]# openstack ip floating create ext-net
    +-------------+--------------------------------------+
    | Field       | Value                                |
    +-------------+--------------------------------------+
    | fixed_ip    | None                                 |
    | id          | ecb79833-4010-48fe-9894-10db69e27254 |
    | instance_id | None                                 |
    | ip          | 172.16.69.31                         |
    | pool        | ext-net                              |
    +-------------+--------------------------------------+
    ```
    
 - Gán IP vừa được cấp phát cho máy ảo `vm6969`
    ```sh
    openstack ip floating add 172.16.69.31 vm6969
    ```
    
 - Đứng từ máy cá nhân, thực hiện lệnh ping để kiểm tra kết nối.
    ```sh
    C:\Users\Administrator>ping 172.16.69.31 -t

    Pinging 172.16.69.31 with 32 bytes of data:
    Reply from 172.16.69.31: bytes=32 time=11ms TTL=62
    Reply from 172.16.69.31: bytes=32 time=15ms TTL=62
    Reply from 172.16.69.31: bytes=32 time=10ms TTL=62
    Reply from 172.16.69.31: bytes=32 time=10ms TTL=62
    
    Ping statistics for 172.16.69.31:
        Packets: Sent = 7, Received = 7, Lost = 0 (0% loss),
    Approximate round trip times in milli-seconds:
        Minimum = 10ms, Maximum = 15ms, Average = 11ms
    ```

<a name="ghichukhac"></a>
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
