
# BASIC COMMANDS FOR INSTANCE CREATION

source /home/stack/overcloudrc ;

# Flavor creation

openstack flavor list ;

openstack flavor create --public m1.tiny --id auto --ram 512 --disk 0 --vcpus 1 --rxtx-factor 1 ;

openstack flavor list ;

# Image creation

curl -O http://download.cirros-cloud.net/0.3.5/cirros-0.3.5-x86_64-disk.img ;

openstack image list ;

openstack image create --container-format bare --disk-format qcow2 --file /home/stack/cirros-0.3.5-x86_64-disk.img cirros ;

openstack image list ;

# Network creation

neutron net-create internal1 ;
neutron net-create internal2 ;

#IPv4 Subnet
neutron subnet-create --name internal1-subnet internal1 192.168.1.0/24 ;
neutron subnet-create --name internal2-subnet internal2 192.168.2.0/24 ;
#IPv6 Subnet
openstack subnet create --subnet-range 2001::/64 --network internal1 --ipv6-address-mode slaac  --ipv6-ra-mode slaac --ip-version 6 internal1-subnet6
openstack subnet create --subnet-range 2002::/64 --network internal2 --ipv6-address-mode slaac  --ipv6-ra-mode slaac --ip-version 6 internal2-subnet6

#External Network
neutron net-create --provider:network_type flat --provider:physical_network datacentre --router:external True --name external ;
neutron subnet-create --name external-subnet --gateway 10.0.0.1 --disable-dhcp --allocation-pool start=10.0.0.50,end=10.0.0.80 external 10.0.0.0/24;

#Tenant Router
openstack router create router1;
openstack router add subnet router1 internal1-subnet;
openstack router add subnet router1 internal2-subnet;
openstack router add subnet router1 internal1-subnet6;
openstack router add subnet router1 internal2-subnet6;
neutron router-gateway-set router1 external;

# Security Group creation
openstack security group create secgroup1 ;
openstack security group rule create secgroup1 --protocol icmp --prefix 0.0.0.0/0 --ingress ;
openstack security group rule create secgroup1 --protocol icmp --prefix 0.0.0.0/0 --egress ;
openstack security group rule create secgroup1 --protocol tcp --prefix 0.0.0.0/0 --ingress;
openstack security group rule create secgroup1 --protocol udp --prefix 0.0.0.0/0 --ingress;
openstack security group rule create secgroup1 --protocol tcp --prefix 0.0.0.0/0 --egress;
openstack security group rule create secgroup1 --protocol udp --prefix 0.0.0.0/0 --egress;


# Keypair creation

openstack keypair create key1 > key.pem ;

chmod 600 key.pem ;

# Instance creation

openstack server create --flavor m1.tiny --security-group secgroup1 --nic net-id=`openstack network list | grep internal1 | awk '{ print $2 }'` --key-name key1 --image cirros instance1 --wait;
openstack server create --flavor m1.tiny --security-group secgroup1 --nic net-id=`openstack network list | grep internal1 | awk '{ print $2 }'` --key-name key1 --image cirros instance2 --wait;

sleep 30 ;

# Assigning floating IP

nova interface-list instance1 ;
neutron floatingip-create external ;
neutron floatingip-associate `openstack floating ip list -c ID -f value` `nova interface-list instance1 | grep ACTIVE | awk '{ print $4 }'` ;

nova interface-list instance2 ;
neutron floatingip-create external ;
neutron floatingip-associate `openstack floating ip list | grep -i none | head -1| awk '{print $2}'` `nova interface-list instance2 | grep ACTIVE | awk '{ print $4 }'`

sleep 10;
nova list ;


