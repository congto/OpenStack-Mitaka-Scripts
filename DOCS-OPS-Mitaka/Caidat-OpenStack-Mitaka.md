# Cài đặt openStack Mitaka

## 1. Chuẩn bị môi trường
### 1.1 Mô hình mạng

![OpenStack Mitaka Topo](/DOCS-OPS-Mitaka/images/Mitaka-topo.png)

### 1.2 Các tham số phần cứng đối với các node
![OpenStack Mitaka Topo](/DOCS-OPS-Mitaka/images/Mitaka-ip-hardware.png)


 
## 2. Bắt đầu cài đặt
- Lưu ý:
 - Đăng nhập với quyền root trên tất cả các bước cài đặt.
 
### 2.1 Cài đặt trên node controller
#### 2.1.1

- Chạy lệnh để cập nhật các gói phần mềm
```sh
apt-get -y update
```

- Thiết lập địa chỉ IP
 - Dùng lệnh `vi` để sửa file `/etc/network/interface`

 ```sh
 # Interface MGNT
 auto eth0
 iface eth0 inet static
 	 address 10.10.10.140
	 netmask 255.255.255.0

 # Interface EXT
 auto eth1
 iface eth1 inet static
	 address 172.16.69.140
	 netmask 255.255.255.0
	 gateway 172.16.69.1
	 dns-nameservers 8.8.8.8
 ```

 - Khởi động lại card mạng sau khi thiết lập IP tĩnh
 ```sh
 ifdown -a && ifup -a
 ```
 - Kiểm tra kết nối tới gateway và internet sau khi thiết lập xong.
 ```sh
 ```

