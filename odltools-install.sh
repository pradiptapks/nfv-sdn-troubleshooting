#!/bin/bash
FS=$'\n' ;

ODLTOOLS=/tmp/odltools-install.log
>$ODLTOOLS

source /home/stack/stackrc
odl_tools(){
	for i in `openstack server list -c Networks -f value | cut -d \= -f 2`
	do
		host_name=`eval 'ssh heat-admin@'$i' sudo hostname -f'`
		echo -e "\n\n[heat-admin@'$host_name'~]$ $1 " | tee -a $ODLTOOLS
		eval 'ssh heat-admin@'$i' $1' | tee -a $ODLTOOLS
	done
}


odl_tools "sudo yum install wget -y"
odl_tools "wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
odl_tools "sudo yum install epel-release-latest-7.noarch.rpm -y"
odl_tools "sudo yum install python-pip -y"
odl_tools "sudo pip install odltools"
odl_tools "sudo pip show odltools"
