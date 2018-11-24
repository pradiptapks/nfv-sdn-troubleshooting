#!/bin/bash

echo "Enter Compute Node IP"
read comp_ip

source /home/stack/stackrc
if [ ! `openstack server list | grep $comp_ip | awk '{print $8}'| cut -d \= -f 2` ]; then
  echo "Compute Node doesn't exist." $comp_ip
  exit 1
fi

echo "Enter OVS Bridge name :"; read br_name
echo "Enter OVS port Number :"; read in_port
echo "Enter Protocol Details :"; read proto
echo "Enter MAC Address of VM's Internal Port whcih associated with FIP :"; read dl_src
echo "Enter MAC Address of Router internal interfae :"; read dl_dst
echo "Enter IP Address of VM Internal network which associated with FIP :"; read nw_src
echo "Enter IP Address of External Physical Gateway :"; read nw_dst

echo "--------------------------";
echo "Open Flow Trace from source port to destination port";
echo "--------------------------";

ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "sudo ovs-appctl ofproto/trace $br_name "in_port=$in_port,$proto,dl_src=$dl_src,dl_dst=$dl_dst,nw_src=$nw_src,nw_dst=$nw_dst""


for i in `ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "sudo ovs-appctl ofproto/trace $br_name "in_port=$in_port,$proto,dl_src=$dl_src,dl_dst=$dl_dst,nw_src=$nw_src,nw_dst=$nw_dst" | cut -c1-3 | grep [0-9]| cut -d \. -f 1"`
do
echo -e "\n============ DUMP FLOW TABLE $i :-"
ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "sudo ovs-ofctl -O OpenFlow13 dump-flows $br_name table:$i"
done



for j in `ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "sudo ovs-appctl ofproto/trace $br_name "in_port=$in_port,$proto,dl_src=$dl_src,dl_dst=$dl_dst,nw_src=$nw_src,nw_dst=$nw_dst" | cut -c1-3 | grep [0-9]| cut -d \. -f 1"`
do
echo -e "\n============ DUMP FLOW GROUP $j :-"
ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "sudo ovs-ofctl -O OpenFlow13 dump-groups $br_name table:$j"
done
