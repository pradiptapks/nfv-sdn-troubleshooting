#!/bin/bash

file=/tmp/osp-tenant-rollback.txt
>$file

echofun() {
  echo -e "\n\n$1" | tee -a $file
}

run_cmd() {
  source /home/stack/overcloudrc ;
  echofun "[stack@`hostname`~]$ $1 "
  eval "$1" | tee -a $file
  if [[ $? -eq 0 ]]; then
	echo -e "$1 || TASK COMPLETED" | tee -a $file
  else
	echo -e "$1 || TASK NOT COMPLETED" | tee -a $file
	exit 1;
  fi
}


run_cmd "openstack server delete instance1";
run_cmd "openstack server delete instance2";
run_cmd "openstack server list";
run_cmd "openstack floating ip list";
for i in `openstack floating ip list -c ID -f value`; do run_cmd "openstack floating ip delete $i"; done
for i in `openstack subnet list -c ID -f value`; do run_cmd "openstack router remove subnet router1 $i"; done
run_cmd "openstack subnet list";
run_cmd "openstack router unset --external-gateway router1";
run_cmd "openstack router delete router1";
run_cmd "openstack router list";
for i in `openstack network list -c ID -f value`; do run_cmd "openstack network delete $i"; done
run_cmd "openstack network list";
for i in `openstack image list -c ID -f value`; do run_cmd "openstack image delete $i"; done
for i in `openstack flavor list -c ID -f value`; do run_cmd "openstack flavor delete $i"; done
run_cmd "openstack security group delete secgroup1";
run_cmd "openstack security group list";
run_cmd "openstack keypair delete key1";
run_cmd "rm -rf /home/stack/key1.pem";
