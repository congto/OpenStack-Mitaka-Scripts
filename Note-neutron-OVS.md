# Ghi chep khi cai dat Neutron - OVS trong OpenStack Mitaka

## Cai dat tren CONTROLLER NODE

### Tao DB

mysql -uroot -pWelcome123
CREATE DATABASE neutron;

GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY 'Welcome123';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' \
  IDENTIFIED BY 'Welcome123';
  
###  To create the service credentials, complete these steps:

openstack user create neutron --domain default --password Welcome123

openstack role add --project service --user neutron admin

openstack service create --name neutron \
    --description "OpenStack Networking" network

openstack endpoint create --region RegionOne \
    network public http://10.10.10.110:9696

openstack endpoint create --region RegionOne \
    network internal http://10.10.10.110:9696

openstack endpoint create --region RegionOne \
    network admin http://10.10.10.110:9696

    
### Cai dat cac thanh phan cua neutron tren CONTROLLER

apt-get -y install neutron-server neutron-plugin-ml2 \
    neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
    neutron-metadata-agent neutron-common python-neutron python-neutronclient \
    ipset
    

