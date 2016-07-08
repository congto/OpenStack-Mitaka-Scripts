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
- File config.cfg chứa các biến mà các script gọi tới. 

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
 - Tùy chọn 1: Nếu sử dụng Linux bridge, chạy file.
 ```sh
 ctl-6-neutron-provider-linuxbridge.sh
 ```
 
 - Tùy chọn 2: Nếu sử dụng OpenvSwitch, chạy file
 ```sh
 ctl-6-neutron-provider-linuxbridge.sh
 ```` 
