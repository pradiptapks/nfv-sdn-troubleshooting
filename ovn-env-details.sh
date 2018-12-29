#!/bin/bash

#################################################################################################################################
# This script has validated in lab enviroment which has deployed by infrared deployer.
# Do not run this script in a production until unless review by a Red Hat OpenStack Engineer.
# This shell script has desgnied to extract alll pre-requiste configuration details which has configure for OVN DVR enviroment.
# It extract all undercloud and overcloud enviroment to /tmp/ovn-env-details.txt which helps to review for further troubleshoot.
#################################################################################################################################

file=/tmp/ovn-env-details.txt
>$file

echofun() {
  echo -e "\n$1" | tee -a $file
}

run_cmd() {
  echofun "[stack@`hostname`~]$ $1 "
  eval "$1" | tee -a $file
}

source /home/stack/stackrc
run_cmd "env |  grep OS_"
run_cmd "openstack server list"

run_cmd '# OverCloud Controller DVR Configuration Details'
for i in `openstack server list -c Name -c Networks -f value | grep controller | cut -d \= -f 2`
do 
run_cmd 'ssh heat-admin@'$i' "sudo grep -i 'enable_distributed_floating_ip' /var/lib/config-data/puppet-generated/neutron/etc/neutron/plugins/ml2/ml2_conf.ini"'
run_cmd 'ssh heat-admin@'$i' "sudo ovs-vsctl list-br"'
run_cmd 'ssh heat-admin@'$i' "sudo ovs-ofctl -O OpenFlow13 dump-ports-desc br-ex"'
done

run_cmd '# OverCloud Compute DVR Configuration Details'
for i in `openstack server list -c Name -c Networks -f value | grep compute | cut -d \= -f 2` 
do
run_cmd 'ssh heat-admin@'$i' "sudo ovs-vsctl list-br"'
run_cmd 'ssh heat-admin@'$i' "sudo ovs-ofctl -O OpenFlow13 dump-ports-desc br-ex"'
done


source /home/stack/overcloudrc
run_cmd "env |  grep OS_"
run_cmd "openstack network agent list"
run_cmd "openstack server list"
for i in `openstack server list -c ID -f value`
do 
run_cmd "openstack server show $i"; 
run_cmd "openstack security group show `openstack server show $i | grep security_groups | cut -d \= -d \' -f 2`"; 
run_cmd "nova interface-list $i"; 

done

run_cmd "openstack network list"
for i in `openstack network list -c ID -f value`
do 
run_cmd "openstack network show $i"
run_cmd "openstack subnet show `openstack network show $i | grep subnet | awk '{print $4}'`"
done
run_cmd "openstack router list"
for i in `openstack router list -c ID -f value`
do 
run_cmd "openstack router show $i"
run_cmd "neutron router-port-list $i"
done
