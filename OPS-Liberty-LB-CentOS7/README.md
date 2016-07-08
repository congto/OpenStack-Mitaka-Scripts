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
- File config.cfg chứa các biến mà các script gọi tới. Sửa các biến về IP để đúng như thực tế, các biến còn lại có thể để nguyên nếu như chưa kiểm soát được script.
- Sửa file `ctl-1-ipadd.sh`
 - Đối với RHEL bỏ comment dòng: 
 ```sh
 yum install https://rdoproject.org/repos/openstack-liberty/rdo-release-liberty.rpm
 ```
 
- Thực thi file  `ctl-1-ipadd.sh` sau khi sửa
```sh
bash ctl-1-ipadd.sh
```

