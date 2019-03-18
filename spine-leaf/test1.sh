## This bash script is under development stage to prepare spine-leaf protocol in Openvswitch layer
## The milestone is replace the linux bridge with as a network-topology plugin in Infrared 
## This script help to dummy layer with network namespace to validate the spine-leaf network testing

#!/bin/bash

BR_LEAF1="leaf1"
BR_LEAF2="leaf2"


# Delete the existing Spine & Leaf OVS bridge
for i in $BR_LEAF1 $BR_LEAF2; do sudo ovs-vsctl del-br br-$i; done
sudo ip netns del NS-$BR_LEAF1
sudo ip netns del NS-$BR_LEAF2

#Create Spine & Leaf OVS bridge
for i in $BR_LEAF1 $BR_LEAF2; do sudo ovs-vsctl add-br br-$i; done

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

sudo ip netns exec NS-$BR_LEAF1 ip address add 127.0.0.1/8 dev lo
sudo ip netns exec NS-$BR_LEAF1 ip link set dev lo up
sudo ip netns exec NS-$BR_LEAF2 ip address add 127.0.0.1/8 dev lo
sudo ip netns exec NS-$BR_LEAF2 ip link set dev lo up


#Assign ip addresses to the interfaces in the namespaces.
sudo ip netns exec NS-$BR_LEAF1 ip address add 10.0.1.10/24 dev vpeer-$BR_LEAF1
sudo ip netns exec NS-$BR_LEAF1 ip link set dev vpeer-$BR_LEAF1 up
sudo ip netns exec NS-$BR_LEAF1 ip route add default via 10.0.1.1
sudo ip netns exec NS-$BR_LEAF2 ip address add 10.0.2.10/24 dev vpeer-$BR_LEAF2
sudo ip netns exec NS-$BR_LEAF2 ip link set dev vpeer-$BR_LEAF2 up
sudo ip netns exec NS-$BR_LEAF2 ip route add default via 10.0.2.1

#IP forwarding can be enabled as follows in the host machine.
echo 1 > /proc/sys/net/ipv4/ip_forward

# Also, enable IP forwarding inside the namespace
sudo ip netns exec NS-$BR_LEAF1 sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec NS-$BR_LEAF2 sysctl -w net.ipv4.ip_forward=1

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

# created veeth pair patch port in-between leaf switch
ovs-vsctl add-port br-$BR_LEAF1 $BR_LEAF1-br-$BR_LEAF2 -- set interface $BR_LEAF1-br-$BR_LEAF2 type=patch -- set interface $BR_LEAF1-br-$BR_LEAF2 options:peer=$BR_LEAF2-br-$BR_LEAF1
ovs-vsctl add-port br-$BR_LEAF2 $BR_LEAF2-br-$BR_LEAF1 -- set interface $BR_LEAF2-br-$BR_LEAF1 type=patch -- set interface $BR_LEAF2-br-$BR_LEAF1 options:peer=$BR_LEAF1-br-$BR_LEAF2

# Manually configured  route inside the bridge
sudo route add -net 10.0.1.0 netmask 255.255.255.0 dev br-$BR_LEAF1
sudo route add -net 10.0.2.0 netmask 255.255.255.0 dev br-$BR_LEAF2

# set host controller to all OVS bridges you want to control
sudo ovs-vsctl set-controller br-$BR_LEAF1 tcp:127.0.0.1:6653 ptcp:6634:127.0.0.1
sudo ovs-vsctl set-controller br-$BR_LEAF2 tcp:127.0.0.1:6653 ptcp:6634:127.0.0.1


## Routing OpenFlow rules from leaf1 to leaf2 and vice-versa
sudo ovs-ofctl add-flow br-$BR_LEAF1 in_port=1,actions=LOCAL
sudo ovs-ofctl add-flow br-$BR_LEAF1 in_port=LOCAL,actions=output:1
sudo ovs-ofctl add-flow br-$BR_LEAF2 in_port=1,actions=LOCAL
sudo ovs-ofctl add-flow br-$BR_LEAF2 in_port=LOCAL,actions=output:1
