echo "Enter OVN Controller Node IP"; read ovn_node;

file=/tmp/ovn-dvr-content.txt
>$file

echofun() {
  echo -e "\n\n$1" | tee -a $file
}

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
