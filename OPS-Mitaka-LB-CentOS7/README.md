# Các bước thực hiện

## CONTROLLER
- Chuẩn bị cài đặt
```sh
yum -y update && yum -y install git

git clone https://github.com/congto/OpenStack-Mitaka-Scripts.git
mv /root/OpenStack-Mitaka-Scripts/OPS-Mitaka-LB-CentOS7/Scripts /root
rm -rf /root/OpenStack-Mitaka-Scripts
cd scripts/
chmod +x *.sh
```
