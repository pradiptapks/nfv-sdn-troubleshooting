## In-Progress 

#!/bin/bash

BR_SPINE1="spine1"
BR_SPINE2="spine2"
BR_LEAF1="leaf1"
BR_LEAF2="leaf2"


# Delete the existing Spine & Leaf OVS bridge
for i in $BR_SPINE1 $BR_SPINE2 $BR_LEAF1 $BR_LEAF2; do sudo ovs-vsctl del-br br-$i; done
sudo ip netns del NS-$BR_LEAF1
sudo ip netns del NS-$BR_LEAF2
ip tuntap del dev tap-$BR_LEAF1 mode tap
ip tuntap del dev tap-$BR_LEAF2 mode tap

#Create Spine & Leaf OVS bridge
for i in $BR_SPINE1 $BR_SPINE2 $BR_LEAF1 $BR_LEAF2; do sudo ovs-vsctl add-br br-$i; done


# VETH patch port to connect in-between leaf switch

# leaf1 <-> leaf2
ovs-vsctl add-port br-$BR_LEAF1 $BR_LEAF1-br-$BR_LEAF2 -- set interface $BR_LEAF1-br-$BR_LEAF2 type=patch -- set interface $BR_LEAF1-br-$BR_LEAF2 options:peer=$BR_LEAF2-br-$BR_LEAF1
ovs-vsctl add-port br-$BR_LEAF2 $BR_LEAF2-br-$BR_LEAF1 -- set interface $BR_LEAF2-br-$BR_LEAF1 type=patch -- set interface $BR_LEAF2-br-$BR_LEAF1 options:peer=$BR_LEAF1-br-$BR_LEAF2

# Spine1 <-> leaf1
ovs-vsctl add-port br-$BR_SPINE1 $BR_SPINE1-br-$BR_LEAF1 -- set interface $BR_SPINE1-br-$BR_LEAF1 type=patch -- set interface $BR_SPINE1-br-$BR_LEAF1 options:peer=$BR_LEAF1-br-$BR_SPINE1
ovs-vsctl add-port br-$BR_LEAF1 $BR_LEAF1-br-$BR_SPINE1 -- set interface $BR_LEAF1-br-$BR_SPINE1 type=patch -- set interface $BR_LEAF1-br-$BR_SPINE1 options:peer=$BR_SPINE1-br-$BR_LEAF1

# Spine1 <-> leaf2
ovs-vsctl add-port br-$BR_SPINE1 $BR_SPINE1-br-$BR_LEAF2 -- set interface $BR_SPINE1-br-$BR_LEAF2 type=patch -- set interface $BR_SPINE1-br-$BR_LEAF2 options:peer=$BR_LEAF2-br-$BR_SPINE1
ovs-vsctl add-port br-$BR_LEAF2 $BR_LEAF2-br-$BR_SPINE1 -- set interface $BR_LEAF2-br-$BR_SPINE1 type=patch -- set interface $BR_LEAF2-br-$BR_SPINE1 options:peer=$BR_SPINE1-br-$BR_LEAF2

# Spine2 <-> leaf1
ovs-vsctl add-port br-$BR_SPINE2 $BR_SPINE2-br-$BR_LEAF1 -- set interface $BR_SPINE2-br-$BR_LEAF1 type=patch -- set interface $BR_SPINE2-br-$BR_LEAF1 options:peer=$BR_LEAF1-br-$BR_SPINE2
ovs-vsctl add-port br-$BR_LEAF1 $BR_LEAF1-br-$BR_SPINE2 -- set interface $BR_LEAF1-br-$BR_SPINE2 type=patch -- set interface $BR_LEAF1-br-$BR_SPINE2 options:peer=$BR_SPINE2-br-$BR_LEAF1

# Spine2 <-> leaf2
ovs-vsctl add-port br-$BR_SPINE2 $BR_SPINE2-br-$BR_LEAF2 -- set interface $BR_SPINE2-br-$BR_LEAF2 type=patch -- set interface $BR_SPINE2-br-$BR_LEAF2 options:peer=$BR_LEAF2-br-$BR_SPINE2
ovs-vsctl add-port br-$BR_LEAF2 $BR_LEAF2-br-$BR_SPINE2 -- set interface $BR_LEAF2-br-$BR_SPINE2 type=patch -- set interface $BR_LEAF2-br-$BR_SPINE2 options:peer=$BR_SPINE2-br-$BR_LEAF2


ip link set dev br-$BR_LEAF1 up;
ip address add 10.0.1.1/24 dev br-$BR_LEAF1
ip link set dev br-$BR_LEAF1 up

ip link set dev br-$BR_LEAF2 up;
ip address add 10.0.2.1/24 dev br-$BR_LEAF2
ip link set dev br-$BR_LEAF2 up

ip link set dev br-$BR_SPINE1 up;
ip address add 10.0.3.1/24 dev br-$BR_SPINE1
ip link set dev br-$BR_SPINE1 up

ip link set dev br-$BR_SPINE2 up;
ip address add 10.0.4.1/24 dev br-$BR_SPINE2
ip link set dev br-$BR_SPINE2 up

#sudo ip tuntap add dev tap-$BR_LEAF1 mode tap
#sudo ip tuntap add dev tap-$BR_LEAF2 mode tap
#
sudo ip netns add NS-$BR_LEAF1
sudo ip netns add NS-$BR_LEAF2
#
#sudo ip link set tap-$BR_LEAF1 netns NS-$BR_LEAF1
#sudo ip link set tap-$BR_LEAF2 netns NS-$BR_LEAF2

sudo ovs-vsctl add-port br-$BR_LEAF1 tap-$BR_LEAF1 -- set interface tap-$BR_LEAF1 type=internal
sudo  ovs-vsctl add-port br-$BR_LEAF2 tap-$BR_LEAF2 -- set interface tap-$BR_LEAF2 type=internal

sudo ip link set tap-$BR_LEAF1 netns NS-$BR_LEAF1
sudo ip link set tap-$BR_LEAF2 netns NS-$BR_LEAF2

#sudo ip netns exec NS-$BR_LEAF1 ip address add 127.0.0.1/8 dev lo
#sudo ip netns exec NS-$BR_LEAF1 ip link set dev lo up
#sudo ip netns exec NS-$BR_LEAF2 ip address add 127.0.0.1/8 dev lo
#sudo ip netns exec NS-$BR_LEAF2 ip link set dev lo up

sudo ip netns exec NS-$BR_LEAF1 ip link set tap-$BR_LEAF1 address fa:16:3e:5c:f6:a2
sudo ip netns exec NS-$BR_LEAF1 ip address add 10.0.1.10/24 dev tap-$BR_LEAF1
sudo ip netns exec NS-$BR_LEAF1 ip link set dev tap-$BR_LEAF1 up
sudo ip netns exec NS-$BR_LEAF1 ip route add default via 10.0.1.1

sudo ip netns exec NS-$BR_LEAF2 ip link set tap-$BR_LEAF2 address fa:16:3e:ac:a5:29
sudo ip netns exec NS-$BR_LEAF2 ip address add 10.0.2.10/24 dev tap-$BR_LEAF2
sudo ip netns exec NS-$BR_LEAF2 ip link set dev tap-$BR_LEAF2 up
sudo ip netns exec NS-$BR_LEAF2 ip route add default via 10.0.2.1

sudo ovs-vsctl set Interface br-$BR_LEAF1 external_ids:iface-id=1873c6e7-2afa-4f83-8d60-7e7d5f5d68ea
sudo ovs-vsctl set Interface br-$BR_LEAF2 external_ids:iface-id=be41d46b-653d-4ab4-a705-e6fcb7cda66f

