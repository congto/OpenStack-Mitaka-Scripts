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
    mv /root/OpenStack-Mitaka-Scripts/OPS-Liberty-LB-CentOS7/scripts /root
    rm -rf /root/OpenStack-Mitaka-Scripts
    cd scripts/
    chmod +x *.sh
    ```
- File `config.cfg` chứa các biến mà các script gọi tới. 

- Sửa các biến về IP để đúng như thực tế, các biến còn lại có thể để nguyên nếu như chưa kiểm soát được script.

- Sửa file `ctl-1-ipadd.sh`
 - Đối với RHEL bỏ comment dòng: 
 
     ```sh
     yum install https://rdoproject.org/repos/openstack-liberty/rdo-release-liberty.rpm
     ```
     
- Thực thi file thiết lập IP cho máy Controller
    ```sh
    bash ctl-1-ipadd.sh
    ```

- Thực thi file cài đặt Repos OpenStack , NTP, Memcache .
    ```sh
    bash ctl-2-prepare.sh
    ```

- Thực thi file cài đặt keystone
    ```sh
    bash ctl-3.keystone.sh
    ```

- Chạy file chứa các biến môi trường
    ```sh
    source admin-openrc
    ```

- Chạy file cài đặt glance
    ```sh
    bash ctl-4-glance.sh
    ```

- Chạy file cài đặt Nova
    ```sh
    bash ctl-5-nova.sh
    ```

- Chạy file cài đặt Neutron (Chỉ chọn một trong hai tùy chọn)
 - Tùy chọn 1: Nếu sử dụng Linux bridge, chạy file. Lưu ý: Khi đó trên Compute node cũng phải chạy file `com1-prepare-linuxbridge.sh`
     ```sh
     bash ctl-6-neutron-provider-linuxbridge.sh
     ```
 
 - Tùy chọn 2: Nếu sử dụng OpenvSwitch, chạy file. Lưu ý: Khi đó trên Compute node cũng phải chạy file `com1-prepare-openvswitch.sh`
     ```sh
     bash ctl-6-neutron-provider-linuxbridge.sh
     ```` 

### Thực hiện trên COMPUTE node
- Có 2 cách thực thi script.
- Cách 1: Dùng lệnh `scp` đứng trên node compute kéo file từ controller node về.

    ```
    scp root@ip_node_controller:/root/scripts /root
    ```
- Cách 2: Tải từ git và sửa các file giống như trong controller: 
     ```sh
    yum -y update && yum -y install git

    git clone https://github.com/congto/OpenStack-Mitaka-Scripts.git
    mv /root/OpenStack-Mitaka-Scripts/OPS-Liberty-LB-CentOS7/scripts /root
    rm -rf /root/OpenStack-Mitaka-Scripts
    cd scripts/
    chmod +x *.sh
    ```
- File config.cfg chứa các biến mà các script gọi tới. 

- Sửa các biến về IP để đúng như thực tế, các biến còn lại có thể để nguyên nếu như chưa kiểm soát được script.

- Kiểm tra xem dòng dưới trong file `com1-ipdd.sh` đã bỏ comment hay chưa 
```sh
yum install https://rdoproject.org/repos/openstack-liberty/rdo-release-liberty.rpm` 
```

- Thực thi script dưới để thiết lập IP cho máy compute
```sh
bash com1-ipdd.sh
```

- Cài đặt nova và neutron trên compute node
 - Đối với ngữ cảnh sử dụng Linux bridge (tương ứng với node controller)
    ```sh
    bash com1-prepare-linuxbridge.sh
    ```
    
 - Đối với ngữ cảnh sử dụng OpenvSwitch (tương ứng với noide controller)
    ```sh
    com1-prepare-openvswitch.sh
    ```
    
### Tạo network, mở security group, tạo máy ảo
- Tao may ao doi voi ngu canh provider network - su dung OVS
```sh
tenantID=`openstack project list | grep service | awk '{print $2}'`

neutron net-create --tenant-id $tenantID sharednet1 \
--shared --provider:network_type flat --provider:physical_network physnet1 

 neutron subnet-create \
--tenant-id $tenantID --gateway 172.16.69.1 --dns-nameserver 8.8.8.8 \
--allocation-pool start=172.16.69.140,end=172.16.69.150 sharednet1 172.16.69.0/24 
```

- Tao may ao - Flat - Provider network
```sh
neutron net-list 
netID=`neutron net-list | grep sharednet1 | awk '{print $2}'` 
nova image-list
nova boot --flavor 1 --image cirros --security_group default --nic net-id=$netID VM01
```

- Create security group rule
```sh
openstack security group rule create --proto icmp default
openstack security group rule create --proto tcp --dst-port 22 default
```





















   
     
     
     