echo "Enter OVN Controller Node IP"; read ovn_node;
echo "Enter OVN Compute Node IP"; read comp_node;
echo "Enter Neutron External Network ID"; read ext_id;
echo "Enter External OVS Bridge name"; read br_name;


file=/tmp/ovn-dvr-content.txt
>$file

echofun() {
  echo -e "\n\n$1" | tee -a $file
}

source /home/stack/overcloudrc


source /home/stack/stackrc

if [ ! `openstack server list | grep $ovn_node | awk '{print $8}'| cut -d \= -f 2` ]; then
  echo "Controller doesn't exist." $ovn_node
  exit 1
else
	run_cmd(){
	host_name=`eval 'ssh heat-admin@'$ovn_node' sudo hostname -f'`
	NB=`eval 'ssh heat-admin@'$ovn_node' sudo grep ^[^#] /var/lib/config-data/puppet-generated/neutron/etc/neutron/plugins/ml2/ml2_conf.ini | grep connection= | cut -d = -f 2 | grep 6641'`
    	SB=`eval 'ssh heat-admin@'$ovn_node' sudo grep ^[^#] /var/lib/config-data/puppet-generated/neutron/etc/neutron/plugins/ml2/ml2_conf.ini | grep connection= | cut -d = -f 2 | grep 6642'`
	LR_LIST=`eval 'ssh heat-admin@'$ovn_node' sudo ovn-nbctl --db=$NB lr-list | cut -d \( -f 2| cut -d \) -f 1'`
	LRP_BIND=`eval 'ssh heat-admin@'$ovn_node' sudo ovn-sbctl --db=$SB find Port_Binding type=chassisredirect | grep options | cut -d \" -f 2'`
	echofun "[heat-admin@'$host_name'~]$ $1 "
	eval 'ssh heat-admin@'$ovn_node' sudo $1' | tee -a $file
	}
fi

if [ ! `openstack server list | grep $comp_node | awk '{print $8}'| cut -d \= -f 2` ]; then
	echo "Compute Node doesn't exist" $comp_node
	exit 1
else
	ovn_trace(){
	comp_name=`eval 'ssh heat-admin@'$comp_node' sudo hostname -f'`
	br_mac=`eval 'ssh heat-admin@'$comp_node' sudo ifconfig br-ex | grep ether | awk '{print $2}''`
	br_ip=`eval 'ssh heat-admin@'$comp_node' sudo ifconfig br-ex | grep netmask | awk '{print $2}''`
	echofun "[heat-admin@'$comp_name'~]$ $1 "
	}	
fi
run_cmd "sleep 10"

source /home/stack/overcloudrc
for i in `openstack network list -c ID -f value` `openstack router list -c ID -f value`
do
	run_cmd "ovn-nbctl --db=$NB show neutron-$i"
done

run_cmd "ovn-sbctl --db=$SB list chassis | grep -A1 hostname"
run_cmd "ovn-nbctl --db=$NB list Logical_Router_port"
run_cmd "ovn-nbctl --db=$NB lr-list"
run_cmd "ovn-nbctl --db=$NB lrp-list $LR_LIST"
run_cmd "ovn-sbctl --db=$SB show"
run_cmd "ovn-sbctl --db=$SB list Port_Binding"
run_cmd "ovn-sbctl --db=$SB find Port_Binding type=chassisredirect"
run_cmd "ovn-nbctl --db=$NB lrp-get-gateway-chassis $LRP_BIND"
run_cmd "ovn-nbctl --db=$NB lr-nat-list $LR_LIST"
run_cmd "ovn-nbctl --db=$NB list Gateway_Chassis"
