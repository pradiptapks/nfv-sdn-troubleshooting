## Under developement

#!/bin/bash
ip link add ​ dcn0​ type veth peer ​ veth0
ip netns add dhcprelay
brctl delif virbr1 ​ em2
brctl addif virbr1 ​ dcn0
ip link set veth0 netns dhcprelay
ip link set em2 netns dhcprelay
ip netns exec dhcprelay ip link set lo up
ip netns exec dhcprelay ip link set ​ em2​ upc
ip netns exec dhcprelay ip link set ​ veth0​ up
ip netns exec dhcprelay brctl addbr br0
ip netns exec dhcprelay brctl addif br0 e
m2
ip netns exec dhcprelay brctl addif br0 v
eth0
ip netns exec dhcprelay ip addr add ​ <edge_gw>​ dev ​ em2
ip netns exec dhcprelay ip addr add ​ <IP in ctlplane-subnet >​ dev ​ veth0
ip netns exec dhcprelay ip route add default via ​ <undercloud_ip>
ip netns exec dhcprelay sysctl net.ipv4.conf.all.proxy_arp=1

# 2 DHCP servers are used: one for introspection and another for deployment
ip netns exec dhcprelay dhcrelay -4 -d -a ​ 172.16.0.1 172.16.0.20 # ← The first

#IP is the undercloud.conf/local_ip parameter, which is used for the
#introspection. The second IP is the IP in the dhcp namespace, typically the
#1st IP in the DHCP range
#It may be obtained with:

(undercloud)$ sudo ip netns exec `ip netns | awk '/dhcp/ {print $1}'` ip addr
| gawk 'match($0, /inet (.*)\/24/, a) {print a[1]}'
