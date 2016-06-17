### Chú ý: 

- Dang ky tren RHEL 7
```sh
subscription-manager register --username dia_chi_email --password mat_khau --auto-attach
```

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

