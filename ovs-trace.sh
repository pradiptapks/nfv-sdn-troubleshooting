#!/bin/bash

echo "Enter Compute Node IP"
read comp_ip

source /home/stack/stackrc
if [ ! `openstack server list | grep $comp_ip | awk '{print $8}'| cut -d \= -f 2` ]; then
  echo "Compute Node doesn't exist." $comp_ip
  exit 1
fi

host_name=`ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "hostname"`

echo "Enter OVS Bridge name :"; read br_name
echo "Enter OVS port Number :"; read in_port
echo "Enter Protocol Details :"; read proto
echo "Enter MAC Address of VM's Internal Port whcih associated with FIP :"; read dl_src
echo "Enter MAC Address of Router internal interfae :"; read dl_dst
echo "Enter IP Address of VM Internal network which associated with FIP :"; read nw_src
echo "Enter IP Address of External Physical Gateway :"; read nw_dst

IFS=$'\n' ;
dir_name=/tmp/ovs-trace
file=$host_name-ofproto-trace.txt
rm -f ${dir_name}/*
mkdir -p ${dir_name}

ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "sudo ovs-appctl ofproto/trace $br_name "in_port=$in_port,$proto,dl_src=$dl_src,dl_dst=$dl_dst,nw_src=$nw_src,nw_dst=$nw_dst"" | tee -a ${dir_name}/$file


for i in `ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "sudo ovs-appctl ofproto/trace $br_name "in_port=$in_port,$proto,dl_src=$dl_src,dl_dst=$dl_dst,nw_src=$nw_src,nw_dst=$nw_dst" | cut -c1-3 | grep [0-9]| cut -d \. -f |tr -d ' '"`
do
echo -e "\n # ovs-ofctl -O OpenFlow13 dump-flows $br_name table:$i" | tee -a ${dir_name}/$file
ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "sudo ovs-ofctl -O OpenFlow13 dump-flows $br_name table:$i" | tee -a ${dir_name}/$file
done

for j in `ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "sudo ovs-appctl ofproto/trace $br_name "in_port=$in_port,$proto,dl_src=$dl_src,dl_dst=$dl_dst,nw_src=$nw_src,nw_dst=$nw_dst" | cut -c1-3 | grep [0-9]| cut -d \. -f 1 |tr -d ' '"`
do
echo -e "\n # ovs-ofctl -O OpenFlow13 dump-groups $br_name table:$j" | tee -a ${dir_name}/$file
ssh -oStrictHostKeyChecking=no heat-admin@$comp_ip "sudo ovs-ofctl -O OpenFlow13 dump-groups $br_name table:$j" | tee -a ${dir_name}/$file
done
