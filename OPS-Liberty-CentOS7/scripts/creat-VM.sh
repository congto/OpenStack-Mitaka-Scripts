selfservice=`openstack network list | awk '/selfservice/ {print $2}'`

openstack server create --flavor m1.tiny --image cirros \
    --nic net-id=$selfservice --security-group default vm6969
    
