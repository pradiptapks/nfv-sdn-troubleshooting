#!/bin/bash

file=/tmp/ovn-env-details.txt
>$file

echofun() {
  echo -e "\n\n$1" | tee -a $file
}

run_cmd() {
  source /home/stack/overcloudrc ;
  echofun "[stack@`hostname`~]$ $1 "
  eval "$1" | tee -a $file
}


run_cmd "openstack flavor list";
run_cmd "openstack flavor create --public m1.tiny --id auto --ram 512 --disk 0 --vcpus 1 --rxtx-factor 1";
run_cmd "openstack flavor list";
run_cmd "curl -O http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img";
run_cmd "openstack image list";
run_cmd "openstack image create --container-format bare --disk-format qcow2 --file /home/stack/cirros-0.3.5-x86_64-disk.img cirros";
run_cmd "openstack image list";
run_cmd "neutron net-create internal1";
run_cmd "neutron net-create internal2";
run_cmd "neutron subnet-create --name internal1-subnet internal1 192.168.1.0/24";
run_cmd "neutron subnet-create --name internal2-subnet internal2 192.168.2.0/24";
run_cmd "openstack subnet create --subnet-range 2001::/64 --network internal1 --ipv6-address-mode slaac  --ipv6-ra-mode slaac --ip-version 6 internal1-subnet6";
run_cmd "openstack subnet create --subnet-range 2002::/64 --network internal2 --ipv6-address-mode slaac  --ipv6-ra-mode slaac --ip-version 6 internal2-subnet6";
run_cmd "neutron net-create --provider:network_type flat --provider:physical_network datacentre --router:external True --name external";
run_cmd "neutron subnet-create --name external-subnet --gateway 10.0.0.1 --disable-dhcp --allocation-pool start=10.0.0.50,end=10.0.0.80 external 10.0.0.0/24";
run_cmd "openstack router create router1";
run_cmd "openstack router add subnet router1 internal1-subnet";
run_cmd "openstack router add subnet router1 internal2-subnet";
run_cmd "openstack router add subnet router1 internal1-subnet6";
run_cmd "openstack router add subnet router1 internal2-subnet6";
run_cmd "neutron router-gateway-set router1 external";
run_cmd "openstack security group create secgroup1";
run_cmd "openstack security group rule create secgroup1 --protocol icmp --ingress"
run_cmd "openstack security group rule create secgroup1 --protocol icmp --egress"
run_cmd "openstack security group rule create secgroup1 --protocol tcp --dst-port 22 --ingress"
run_cmd "openstack security group rule create secgroup1 --protocol tcp --dst-port 22 --egress"
#run_cmd "openstack security group rule create secgroup1 --protocol icmp --prefix 0.0.0.0/0 --ingress";
#run_cmd "openstack security group rule create secgroup1 --protocol icmp --prefix 0.0.0.0/0 --egress";
#run_cmd "openstack security group rule create secgroup1 --protocol tcp --prefix 0.0.0.0/0 --ingress";
#run_cmd "openstack security group rule create secgroup1 --protocol udp --prefix 0.0.0.0/0 --ingress";
#run_cmd "openstack security group rule create secgroup1 --protocol tcp --prefix 0.0.0.0/0 --egress";
#run_cmd "openstack security group rule create secgroup1 --protocol udp --prefix 0.0.0.0/0 --egress";
run_cmd "openstack keypair create key1 > key.pem";
run_cmd "chmod 600 key.pem";
run_cmd "openstack server create --flavor m1.tiny --security-group secgroup1 --nic net-id=`openstack network list | grep internal1 | awk '{ print $2 }'` --key-name key1 --image cirros instance1 --wait";
run_cmd "openstack server create --flavor m1.tiny --security-group secgroup1 --nic net-id=`openstack network list | grep internal1 | awk '{ print $2 }'` --key-name key1 --image cirros instance2 --wait";
run_cmd "nova interface-list instance1";
run_cmd "neutron floatingip-create external";
run_cmd "neutron floatingip-associate `openstack floating ip list -c ID -f value` `nova interface-list instance1 | grep ACTIVE | awk '{ print $4 }'`";
run_cmd "nova interface-list instance2";
run_cmd "neutron floatingip-create external";
run_cmd "neutron floatingip-associate `openstack floating ip list | grep -i none | head -1| awk '{print $2}'` `nova interface-list instance2 | grep ACTIVE | awk '{ print $4 }'`";
run_cmd "openstack server list";
