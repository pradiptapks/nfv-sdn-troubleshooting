#!/bin/bash
FS=$'\n' ;
dir_name=/tmp/OC
rm -rf ${dir_name}/*
mkdir -p ${dir_name}

source /home/stack/stackrc
stackname=`openstack stack list -c "Stack Name" -f value`

run_cmd() {
  echo -e "\n\n[stack@`hostname`~]$ $1 "
  eval "$1" | tee -a ${dir_name}/`hostname`_env.log
}

resource(){
  echo -e "\n\n[stack@`hostname`~]$ $1 "
  eval "$1" | tee -a ${dir_name}/$stackname.log
}

journal_log() {
    for i in `openstack server list -c Networks -f value | cut -d \= -f 2`
    do
    host_name=`eval 'ssh heat-admin@'$i' sudo hostname -f'`
    echo -e "\n\n[heat-admin@'$host_name'~]$ $1 " | tee -a ${dir_name}/$host_name.log
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

journal_log "sudo journalctl -u os-collect-config"

resource "openstack stack resource list -n 5 --fit-width  $stackname"
resource "openstack stack list --nested --fit-width"

openstack stack resource list -n 5 $stackname -c resource_name -f value | grep [a-zA-Z] | sort --unique | while read line; do 
  resource "openstack stack resource show --fit-width $stackname $line"
done
openstack stack resource list -n 5 $stackname | grep -i deployment | awk '{print $4}' |grep -v $stackname | while read line; do 
  resource "openstack software deployment show $line"
  resource "openstack software deployment output show --all --long $line"
done

resource 'openstack stack hook poll --nested-depth 5 --fit-width $stackname'

archive_name="`hostname`_`date '+%F_%H%m%S'`_Overcloud_details.tar.gz";
tar -czf $archive_name ${dir_name};
echo "Archived all data in archive ${archive_name}";
