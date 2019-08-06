#!/bin/bash

file=/tmp/osp-env-create.txt
>$file

echofun() {
  echo -e "\n\n$1" | tee -a $file
}

run_cmd() {
  source /home/stack/overcloudrc ;
  echofun "[stack@`hostname`~]$ $1 "
  eval "$1" | tee -a $file
  if [[ $? -eq 0 ]]; then
        echo -e "\n........ TASK COMPLETED" | tee -a $file
  else
        echo -e "\n........ TASK NOT COMPLETED" | tee -a $file
        exit 1;
  fi
  sleep 10;
}

delete_tenant() {
  	source /home/stack/overcloudrc ;

	for i in `openstack server list -c ID -f value`; 
		do run_cmd "openstack server delete $i --wait"; done
		run_cmd "openstack server list --long";

	run_cmd "openstack floating ip list";
	for i in `openstack floating ip list -c ID -f value`; 
		do run_cmd "openstack floating ip delete $i"; done

	for i in `openstack port list -c ID -f value`; 
		do run_cmd "openstack port delete $i";done
		run_cmd "openstack port list";

	for i in `openstack network list -c ID -f value`; 
		do run_cmd "openstack network delete $i"; done
		run_cmd "openstack network list";

	for i in `openstack image list -c ID -f value`; 
		do run_cmd "openstack image delete $i"; done

	for i in `openstack flavor list -c ID -f value`; 
		do run_cmd "openstack flavor delete $i"; done


	for i in `openstack security group list -c ID -f value`;
		do run_cmd "openstack security group delete $i"; done
		run_cmd "openstack security group list";

	for i in `openstack keypair list -c Name -f value`;
		do run_cmd "openstack keypair delete $i"; done
	aggregate=`openstack aggregate list -c Name -f value`;
	for i in `openstack hypervisor list -c "Hypervisor Hostname" -f value`;
		do run_cmd "openstack aggregate remove host $aggregate $i";
		done
		run_cmd "openstack aggregate delete $aggregate";
		run_cmd "openstack aggregate list"

	run_cmd "ls -l /home/stack/*.pem";
	run_cmd "rm -rf /home/stack/*.pem";
}

create_tenant () {
	run_cmd "openstack aggregate create --zone=nfvprovider nfvprovider";
	for i in `openstack hypervisor list -c "Hypervisor Hostname" -f value`;
		do run_cmd "openstack aggregate add host nfvprovider $i"; done

	run_cmd "openstack flavor list";
	run_cmd "openstack flavor create nfv-numa --id auto --ram 8192 --disk 30 --vcpus 8 --property hw:cpu_policy='dedicated' --property hw:mem_page_size='1GB' --property hw:emulator_threads_policy='isolate' --property hw:isolated_metadata='true'";
	run_cmd "openstack flavor list --long";


	run_cmd "curl -O http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img";
	run_cmd "openstack image list";
	run_cmd "openstack image create --container-format bare --disk-format qcow2 --file /home/stack/cirros-0.3.5-x86_64-disk.img cirros";
	run_cmd "openstack image create --container-format bare --disk-format qcow2 --file /home/stack/rhel-server-7.6-x86_64-kvm.qcow2 rhel";
	run_cmd "openstack image list --long";


	run_cmd "openstack network create --share --provider-physical-network external --provider-network-type vlan --provider-segment 220 External";
	run_cmd "openstack subnet create --network External --gateway 10.74.193.174 --subnet-range 10.74.193.160/28 external-subnet";
	run_cmd "openstack subnet set --dns-nameserver 10.75.5.25 --dns-nameserver 10.38.5.26 --dns-nameserver 8.8.8.8 external-subnet";
	run_cmd "openstack subnet show external-subnet";

	run_cmd "openstack network create --share --provider-physical-network offload1 --provider-network-type flat provider-1";
	run_cmd "openstack subnet create --network provider-1 --gateway 192.168.100.1 --subnet-range 192.168.100.0/24 provider-subnet-1";
	run_cmd "openstack network create --share --provider-physical-network offload2 --provider-network-type flat provider-2";
	run_cmd "openstack subnet create --network provider-2 --gateway 192.168.200.1 --subnet-range 192.168.200.0/24 provider-subnet-2";

	run_cmd "openstack security group create secgroup1";
	run_cmd "openstack security group rule create secgroup1 --protocol icmp --prefix 0.0.0.0/0 --ingress";
	run_cmd "openstack security group rule create secgroup1 --protocol icmp --prefix 0.0.0.0/0 --egress";
	run_cmd "openstack security group rule create secgroup1 --protocol tcp --prefix 0.0.0.0/0 --ingress";
	run_cmd "openstack security group rule create secgroup1 --protocol udp --prefix 0.0.0.0/0 --ingress";
	run_cmd "openstack security group rule create secgroup1 --protocol tcp --prefix 0.0.0.0/0 --egress";
	run_cmd "openstack security group rule create secgroup1 --protocol udp --prefix 0.0.0.0/0 --egress";
	security=`openstack security group list -c Name -f value | grep secgroup1`

	run_cmd "openstack keypair create key1 > key.pem";
	run_cmd "chmod 600 key.pem";

	openstack port create --network provider-1 --vnic-type direct --security-group $security --binding-profile '{"capabilities": ["switchdev"]}' provider1-port1;
	openstack port create --network provider-2 --vnic-type direct --security-group $security --binding-profile '{"capabilities": ["switchdev"]}' provider2-port1;

	run_cmd "openstack port create --network provider-1 --vnic-type direct provider-1-sriov-port1";
	run_cmd "openstack port create --network provider-2 --vnic-type direct provider-2-sriov-port1";

	run_cmd "openstack port create --network External --security-group $security external1"
	run_cmd "openstack port create --network External --security-group $security external2"


	provider1_port1=`openstack port list | grep provider1-port1 | awk '{print $2}'`
	provider2_port1=`openstack port list | grep provider2-port1 | awk '{print $2}'`
	provider1_sriov_port1=`openstack port list | grep provider-1-sriov-port1 | awk '{print $2}'`
	provider2_sriov_port1=`openstack port list | grep provider-2-sriov-port1 | awk '{print $2}'`
	external_port1=`openstack port list | grep external1 | awk '{print $2}'`
	external_port2=`openstack port list | grep external2 | awk '{print $2}'`
	nfv_numa=`openstack flavor list | grep nfv-numa | awk '{print $2}'`


	run_cmd "openstack server create --flavor $nfv_numa --security-group $security --nic port-id=$external_port1 --nic port-id=$provider1_port1 --nic port-id=$provider2_port1 --key-name key1 --image rhel --availability-zone nfvprovider:nfv-compute-offload-0.localdomain TestPMD --wait";

	run_cmd "openstack server create --flavor $nfv_numa --security-group $security --nic port-id=$external_port2 --nic port-id=$provider1_sriov_port1 --nic port-id=$provider2_sriov_port1 --key-name key1 --image rhel --availability-zone nfvprovider:nfv-compute-sriov-0.localdomain TRex --wait";
}

delete_tenant;
create_tenant;
