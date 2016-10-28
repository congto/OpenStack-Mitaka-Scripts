#!/bin/bash -ex

source config.cfg
source functions.sh

WORK_DIR=$(dirname $0)

# Kiem tra lai file config
echo "IP Controller ext is $CTL_MGNT_IP"
echo "IP Controller int is $CTL_EXT_IP"
echo "Hostname Controller is $HOST_CTL"
echo "Password default is $DEFAULT_PASS"
sleep 5

# Cai dat cac goi can thiet
echo -e "\e[1;42m Installing prepare package \e[1;0m"
	$WORK_DIR/ctl-2-prepare.sh

# Cai dat keystone
echo -e "\e[1;42m Installing keystone \e[1;0m"
	$WORK_DIR/ctl-3.keystone.sh

# Cai dat glance
echo -e "\e[1;42m Installing glance \e[1;0m"
	$WORK_DIR/ctl-4-glance.sh

# Cai dat nova
echo -e "\e[1;42m Installing nova \e[1;0m"
	$WORK_DIR/ctl-5-nova.sh

# Cai dat neutron
echo -e "\e[1;42m Installing neutron \e[1;0m"
	echo "Do you want to install neutron with OVS as provider|selfservice|both? Enter P|S|B to continue or E to exit. "
	while [[ true ]]; do
		read answer_neutron
		case $answer_neutron in 
			p|P)
				echocolor "You choise Provider"
				$WORK_DIR/ctl-6-neutron-OVS-provider.sh
				break
				;;
			s|S)
				echocolor "You choise Selfservice"
				$WORK_DIR/ctl-6-neutron-OVS-selfservice.sh
				break
				;;
			b|B)
				echocolor "You choise both Provider and Selfservice"
				$WORK_DIR/ctl-6-neutron.sh
				break
				;;
			e|E)
				echocolor "You don't install neutron."
				break
				;;
			*)
				echocolor "You must choise P|S|B to install continue or E to exit."
				;;
		esac
	done
	
echo -e "\e[1;42m Installed Controller \e[1;0m"