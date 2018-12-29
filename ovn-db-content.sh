#!/bin/bash

################################################################################################################################
# This script is useful to extract the OVN North and South Bound DB content w.r.t its logical network created by neutron API.
# The script has successfully validated in RHOSP14lab enviroment which deployed via Infrared 2.0
# It would be recoomend to review by Red Hat OpenStack Engineer before execute in a production enviroment.
################################################################################################################################

file=/tmp/ovn-db-content.txt
>$file

echofun() {
  echo -e "\n\n$1" | tee -a $file
}

source /home/stack/stackrc
eval 'env | grep OS_' | tee -a $file
eval 'openstack server list' | tee -a $file

run_cmd() {
    for i in `openstack server list -c Name -c Networks -f value | grep controller | cut -d \= -f 2`
    do
    host_name=`eval 'ssh heat-admin@'$i' sudo hostname -f'`
    NB=`eval 'ssh heat-admin@'$i' sudo grep ^[^#] /var/lib/config-data/puppet-generated/neutron/etc/neutron/plugins/ml2/ml2_conf.ini | grep connection= | cut -d = -f 2 | grep 6641'`
    SB=`eval 'ssh heat-admin@'$i' sudo grep ^[^#] /var/lib/config-data/puppet-generated/neutron/etc/neutron/plugins/ml2/ml2_conf.ini | grep connection= | cut -d = -f 2 | grep 6642'`
    echofun "[heat-admin@'$host_name'~]$ $1 "
    eval 'ssh heat-admin@'$i' $1' | tee -a $file
    done
}
run_cmd "sudo sleep 10"
run_cmd "sudo ovn-nbctl --db=$NB show"
run_cmd "sudo ovn-nbctl --db=$NB list Logical_Switch"
run_cmd "sudo ovn-nbctl --db=$NB list Logical_Switch_Port"
run_cmd "sudo ovn-nbctl --db=$NB list ACL"
run_cmd "sudo ovn-nbctl --db=$NB list Address_Set"
run_cmd "sudo ovn-nbctl --db=$NB list Logical_Router"
run_cmd "sudo ovn-nbctl --db=$NB list Logical_Router_Port"
run_cmd "sudo ovn-nbctl --db=$NB list Gateway_Chassis"
run_cmd "sudo ovn-sbctl --db=$SB list Chassis"
run_cmd "sudo ovn-sbctl --db=$SB list Encap"
run_cmd "sudo ovn-nbctl --db=$NB list Address_Set"
run_cmd "sudo ovn-sbctl --db=$SB lflow-list"
run_cmd "sudo ovn-sbctl --db=$SB list Multicast_Group"
run_cmd "sudo ovn-sbctl --db=$SB list Datapath_Binding"
run_cmd "sudo ovn-sbctl --db=$SB list Port_Binding"
run_cmd "sudo ovn-sbctl --db=$SB list MAC_Binding"
run_cmd "sudo ovn-sbctl --db=$SB list Gateway_Chassis"
