#!/bin/bash
FS=$'\n' ;
dir_name=/tmp/OC
rm -rf ${dir_name}/*
mkdir -p ${dir_name}
file=`hostname`_env.txt

source /home/stack/stackrc
stackname=`openstack stack list -c "Stack Name" -f value`

echofun() {
  echo -e "\n\n$1" | tee -a ${dir_name}/$file
}

run_cmd() {
  echofun "[stack@`hostname`~]$ $1 "
  eval "$1" | tee -a ${dir_name}/$file
}

os_collect() {
    for i in `openstack server list -c Networks -f value | cut -d \= -f 2`
    do
    host_name=`eval 'ssh heat-admin@'$i' sudo hostname -f'`
    echofun "[heat-admin@'$host_name'~]$ $1 " | tee -a ${dir_name}/$host_name.log
    eval 'ssh heat-admin@'$i' $1' | tee -a ${dir_name}/$host_name.log
    done
}

run_cmd "openstack stack list"
run_cmd "openstack server list"
run_cmd "openstack hypervisor list"
run_cmd "openstack compute service list"
run_cmd "openstack baremetal node list"
run_cmd "openstack baremetal introspection list"
run_cmd "openstack hypervisor list"

for i in `openstack hypervisor list -c "Hypervisor Hostname" -f value`; do run_cmd "openstack hypervisor show $i"; done
for i in `openstack baremetal node list -c UUID -f value`; do run_cmd "openstack baremetal introspection status $i"; run_cmd "openstack baremetal node show $i"; run_cmd "openstack baremetal introspection interface list $i"; done

os_collect "sudo journalctl -u os-collect-config"

run_cmd "openstack stack resource list -n 5 --fit-width  $stackname"
run_cmd "openstack stack list --nested --fit-width"

openstack stack resource list -n 5 $stackname -c resource_name -f value | grep [a-zA-Z] | sort --unique | while read line; do 
  run_cmd "openstack stack resource show --fit-width $stackname $line"
done
openstack stack resource list -n 5 $stackname | grep -i deployment | awk '{print $4}' |grep -v $stackname | while read line; do 
  run_cmd "openstack software deployment show $line"
  run_cmd "openstack software deployment output show --all --long $line"
done

run_cmd 'openstack stack hook poll --nested-depth 5 --fit-width $stackname'

archive_name="`hostname`_`date '+%F_%H%m%S'`_Overcloud_details.tar.gz";
tar -czf $archive_name ${dir_name};
echo "Archived all data in archive ${archive_name}";
