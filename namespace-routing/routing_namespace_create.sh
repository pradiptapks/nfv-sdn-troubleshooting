#!/bin/bash

S1="veth0"
S2M1="veth1"
M2R1="veth2"
R1="veth3"

NS_SND="ns_snd"
NS_RCV="ns_rcv"
NS_MID="ns_mid"


#Remove existing namespace
sudo ip netns del $NS_SND
sudo ip netns del $NS_RCV
sudo ip netns del $NS_MID

#Remove existing veth pairs
sudo ip link del $S1
sudo ip link del $R1
sudo ip link del $S2M1
sudo ip link del $M2R1

#Create veth pairs
sudo ip link add $S1 type veth peer name $S2M1
sudo ip link add $M2R1 type veth peer name $R1

#Bring up
sudo ip link set dev $S1 up
sudo ip link set dev $S2M1 up
sudo ip link set dev $M2R1 up
sudo ip link set dev $R1 up


#Create the specific namespaces
sudo ip netns add $NS_SND
sudo ip netns add $NS_RCV
sudo ip netns add $NS_MID

#Move the interfaces to the namespace
sudo ip link set $S1 netns $NS_SND
sudo ip link set $S2M1 netns $NS_MID
sudo ip link set $M2R1 netns $NS_MID
sudo ip link set $R1 netns $NS_RCV

#Configure the loopback interface in namespace
sudo ip netns exec $NS_SND ip address add 127.0.0.1/8 dev lo
sudo ip netns exec $NS_SND ip link set dev lo up
sudo ip netns exec $NS_RCV ip address add 127.0.0.1/8 dev lo
sudo ip netns exec $NS_RCV ip link set dev lo up
sudo ip netns exec $NS_MID ip address add 127.0.0.1/8 dev lo
sudo ip netns exec $NS_MID ip link set dev lo up

#add bridge
sudo ip netns exec $NS_MID brctl addbr br549
sudo ip netns exec $NS_MID brctl addif br549 $S2M1
sudo ip netns exec $NS_MID brctl addif br549 $M2R1
sudo ip netns exec $NS_RCV ip route add 10.0.0.0/30 via 10.0.0.5

#Bring up interface in namespace
sudo ip netns exec $NS_SND ip link set dev $S1 up
sudo ip netns exec $NS_SND ip address add 10.0.0.1/30 dev $S1
sudo ip netns exec $NS_MID ip link set dev $S2M1 up
sudo ip netns exec $NS_MID ip address add 10.0.0.2/30 dev $S2M1
sudo ip netns exec $NS_MID ip link set dev $M2R1 up
sudo ip netns exec $NS_MID ip address add 10.0.0.5/30 dev $M2R1
sudo ip netns exec $NS_RCV ip link set dev $R1 up
sudo ip netns exec $NS_RCV ip address add 10.0.0.6/30 dev $R1

#Add ip routes
sudo ip netns exec $NS_SND ip route add 10.0.0.4/30 via 10.0.0.2
sudo ip netns exec $NS_RCV ip route add 10.0.0.0/30 via 10.0.0.5

sudo ip netns exec $NS_MID sysctl -w net.ipv4.ip_forward=1
