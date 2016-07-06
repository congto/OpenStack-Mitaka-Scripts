# Ghi chep khi cai dat Neutron - OVS trong OpenStack Mitaka

## Cai dat tren CONTROLLER NODE


echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
sysctl -p 

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

    
### Cai dat cac thanh phan cua neutron tren 10.10.10.110

apt-get -y install neutron-server neutron-plugin-ml2 \
    neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent \
    neutron-metadata-agent neutron-common python-neutron python-neutronclient \
    ipset
    

### Cau hinh cho neutron tren 10.10.10.110 NODE
#### Sua file /etc/neutron/neutron.conf 

cp /etc/neutron/neutron.conf  /etc/neutron/neutron.conf.orig

- Sua trong section [DATABASE]

connection = mysql+pymysql://neutron:Welcome123@10.10.10.110/neutron

- Sua trong section [DEFAULT]

core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
rpc_backend = rabbit
auth_strategy = keystone

notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True


- Sua trong section [oslo_messaging_rabbit]

rabbit_host = 10.10.10.110
rabbit_userid = openstack
rabbit_password = Welcome123

- Sua trong section [keystone_authtoken]

auth_uri = http://10.10.10.110:5000
auth_url = http://10.10.10.110:35357
memcached_servers = 10.10.10.110:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = Welcome123


- Sua trong section [nova]

auth_url = http://10.10.10.110:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = Welcome123



- check config 
cat /etc/neutron/neutron.conf | egrep -v '^$|^#'

### Sua file /etc/neutron/plugins/ml2/ml2_conf.ini

cp /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig

- [ml2] section

type_drivers = flat,vlan,vxlan,gre
tenant_network_types = vlan,gre,vxlan
mechanism_drivers = openvswitch,l2population
extension_drivers = port_security

- [ml2_type_flat] section

flat_networks = external

- [ml2_type_vlan] section
# network_vlan_ranges = external

- [ml2_type_gre] section

tunnel_id_ranges = 300:400

- [ml2_type_vxlan]
# vni_ranges = 500:600

- [securitygroup] section

enable_security_group = True
enable_ipset = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver


- check config 
cat /etc/neutron/plugins/ml2/ml2_conf.ini | egrep -v '^$|^#'


### Sua file /etc/neutron/plugins/ml2/openvswitch_agent.ini
cp /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig


- [ovs] section

local_ip = 10.10.10.110
bridge_mappings = vlan:br-vlan,external:br-ex

- [agent] section

tunnel_types = gre,vxlan
l2_population = True

- [securitygroup] section

firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

- check config 
cat /etc/neutron/plugins/ml2/openvswitch_agent.ini | egrep -v '^$|^#'


### Sua file /etc/neutron/l3_agent.ini

- [DEFAULT] Section

interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
external_network_bridge =

- check config 
cat /etc/neutron/l3_agent.ini | egrep -v '^$|^#'

### Sua file /etc/neutron/dhcp_agent.ini

cp /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.orig


- [DEFAULT] section 

interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = True

- Check config 
cat /etc/neutron/dhcp_agent.ini | egrep -v '^$|^#'

### Sua file /etc/neutron/metadata_agent.ini

cp /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig

- Section [DEFAULT]

nova_metadata_ip = 10.10.10.110
metadata_proxy_shared_secret = Welcome123

- Check config 
cat /etc/neutron/metadata_agent.ini | egrep -v '^$|^#'

### Update db cuar neutron 

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
  

### Khoi dong cac dich vu cua neutron

service nova-api restart
service nova-scheduler restart
service nova-conductor restart

service neutron-server restart
service neutron-openvswitch-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart



### add interface for OVS

ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex eth1



### Khoi dong lai may
init 6

### Kiem tra dich vu neutron




###############

- check config 
cat /etc/neutron/neutron.conf | egrep -v '^$|^#'

- check config 
cat /etc/neutron/plugins/ml2/ml2_conf.ini | egrep -v '^$|^#'

- check config 
cat /etc/neutron/plugins/ml2/openvswitch_agent.ini | egrep -v '^$|^#'

- check config 
cat /etc/neutron/l3_agent.ini | egrep -v '^$|^#'

- Check config 
cat /etc/neutron/dhcp_agent.ini | egrep -v '^$|^#'

- Check config 
cat /etc/neutron/metadata_agent.ini | egrep -v '^$|^#'






