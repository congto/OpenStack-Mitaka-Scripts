### Chú ý: 

- Đăng ký để cài đặt với RHEL
```sh
subscription-manager register --username dia_chi_email --password mat_khau --auto-attach
```

- Kiểm tra phiên bản CENTOS
```sh
[root@ctl-cent7 scripts]# cat /etc/redhat-release
CentOS Linux release 7.2.1511 (Core)
[root@ctl-cent7 scripts]#
``

# Các bước thực hiện

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

