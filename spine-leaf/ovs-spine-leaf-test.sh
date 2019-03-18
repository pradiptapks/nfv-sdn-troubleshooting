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
#ip tuntap del dev tap-$BR_LEAF1 mode tap
#ip tuntap del dev tap-$BR_LEAF2 mode tap

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

# Create Name space.
sudo ip netns add NS-$BR_LEAF1
sudo ip netns add NS-$BR_LEAF2

# Created VETH pair interface
sudo ip link add tap-$BR_LEAF1 type veth peer name vpeer-$BR_LEAF1
sudo ip link add tap-$BR_LEAF2 type veth peer name vpeer-$BR_LEAF2

# Bring UP the tap interface
sudo ip link set tap-$BR_LEAF1 up
sudo ip link set tap-$BR_LEAF2 up

# Add the peer interfaces to the corresponding namespaces.
sudo ip link set vpeer-$BR_LEAF1 netns NS-$BR_LEAF1
sudo ip link set vpeer-$BR_LEAF2 netns NS-$BR_LEAF2

#Assign ip addresses to the interfaces in the namespaces.
sudo ip netns exec NS-$BR_LEAF1 ip address add 10.0.1.10/24 dev vpeer-$BR_LEAF1
sudo ip netns exec NS-$BR_LEAF1 ip link set dev vpeer-$BR_LEAF1 up
sudo ip netns exec NS-$BR_LEAF2 ip address add 10.0.2.10/24 dev vpeer-$BR_LEAF2
sudo ip netns exec NS-$BR_LEAF2 ip link set dev vpeer-$BR_LEAF2 up

#IP forwarding can be enabled as follows in the host machine.
echo 1 > /proc/sys/net/ipv4/ip_forward

# add the veth interfaces to OVS bridge
sudo ovs-vsctl add-port br-$BR_LEAF1 tap-$BR_LEAF1
sudo ovs-vsctl add-port br-$BR_LEAF2 tap-$BR_LEAF2

# Assign the gateway IP to Spine & Leaf bridges
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

