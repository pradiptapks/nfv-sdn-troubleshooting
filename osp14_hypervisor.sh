#!/bin/bash
FS=$'\n' ;
dir_name=/tmp/OSP14
rm -rf ${dir_name}/*
mkdir -p ${dir_name}

source /home/stack/stackrc
stackname=`openstack stack list -c "Stack Name" -f value`

director() {
  echo -e "\n\n[stack@`hostname`~]$ $1 " | tee -a ${dir_name}/`hostname`_env.log
  eval "$1" | tee -a ${dir_name}/`hostname`_env.log
}

ansible_log(){
  echo -e "\n\n[stack@`hostname`~]$ $1 " | tee -a ${dir_name}/${stackname}_ansible_details.log
  eval "$1" | tee -a ${dir_name}/${stackname}_ansible_details.log
}

puppet_debug(){
for i in `openstack server list -c Networks -f value | cut -d \= -f 2`
do
	host_name=`eval 'ssh heat-admin@'$i' sudo hostname -f'`
	echo -e "\n\n[heat-admin@'$host_name'~]$ $1 " | tee -a ${dir_name}/${host_name}_puppet_debug.log
	eval 'ssh heat-admin@'$i' $1' | tee -a ${dir_name}/${host_name}_puppet_debug.log
done
}

director "openstack stack list"
director "openstack server list"
director "openstack hypervisor list"
director "openstack baremetal node list"
director "openstack baremetal introspection list"
director "openstack hypervisor list"
director "openstack overcloud failures"
director "openstack overcloud status"
director "openstack stack failures list --long overcloud"
for i in `openstack hypervisor list -c "Hypervisor Hostname" -f value`; do director "openstack hypervisor show $i"; done
for i in `openstack baremetal node list -c UUID -f value`; do director "openstack baremetal introspection status $i"; director "openstack baremetal node show --fit-width $i"; director "openstack baremetal introspection interface list $i"; done

ansible_log 'ansible -i /usr/bin/tripleo-ansible-inventory --become -a "grep -ir status_code /var/lib/heat-config/deployed" overcloud'
ansible_log "openstack overcloud config download --name $stackname --config-dir ${dir_name}/${stackname}_config"
ansible_log "tripleo-ansible-inventory --list | python -m json.tool"
ansible_log "tripleo-ansible-inventory --static-inventory ${dir_name}/static-inventory"

puppet_debug "sudo hiera -c /etc/puppet/hiera.yaml step"
puppet_debug "sudo puppet apply --debug /var/lib/tripleo-config/puppet_step_config.pp"

archive_name="`hostname`_`date '+%F_%H%m%S'`_Overcloud_details.tar.gz";
tar -czf $archive_name ${dir_name};
echo "Archived all data in archive ${archive_name}";
