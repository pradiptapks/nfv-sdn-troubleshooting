#!/bin/bash -x

##########################################################################################################
# OVS-DPDK Physical reciveing queue drop analysis, 	
# The script have limited condition to run 12hour and specfic to Compute configuration.
# It is not yet ready to run for any generic validation and required a best practice to customising
###########################################################################################################

IFS=$'\n' ;
dir_name=/tmp/dpdk_statistcs
rm -rf ${dir_name}/*
mkdir -p ${dir_name}

yum install sysstat -y;

ovs_dbg_on() {
for i in dpdk dpif_netdev netdev netdev_dpdk pmd_perf ofproto_xlate_cache lacp lldp ovs_thread poll_loop timeval; 
do 
	ovs-appctl vlog/set $i:file:dbg ; 
done
}

ovs_dbg_off() {
for i in dpdk dpif_netdev netdev netdev_dpdk pmd_perf ofproto_xlate_cache lacp lldp ovs_thread poll_loop timeval; 
do 
	ovs-appctl vlog/set $i:file:info ; 
done
}

sos_report() {
sosreport --batch;
}

archive_log() {
archive_name="OVS-DPDK_`hostname`_`date '+%F_%H%m%S'`_Statistics.tar.gz";
tar -czf $archive_name ${dir_name};
echo "Archived all data in archive ${archive_name}";
}

ovs_clean() {
  echo -e "\n\n[`whoami`@`hostname`~]$ $(date '+TIME:%H:%M:%S') " | tee -a ${dir_name}/`hostname`_ovs_clean.log
  echo -e "[`whoami`@`hostname`~]$ $1 "| tee -a ${dir_name}/`hostname`_ovs_clean.log
  eval "sudo $1" | tee -a ${dir_name}/`hostname`_ovs_clean.log
}



drp_counter() {
  echo -e "\n\n[`whoami`@`hostname`~]$ $(date '+TIME:%H:%M:%S') " | tee -a ${dir_name}/`hostname`_dpdk_drop.log
  echo -e "[`whoami`@`hostname`~]$ $1 " | tee -a ${dir_name}/`hostname`_dpdk_drop.log
  eval "sudo $1" | tee -a ${dir_name}/`hostname`_dpdk_drop.log
}

ovs_stat() {
  echo -e "\n\n[`whoami`@`hostname`~]$ $(date '+TIME:%H:%M:%S') " | tee -a ${dir_name}/`hostname`_ovs_stats.log
  echo -e "[`whoami`@`hostname`~]$ $1 " | tee -a ${dir_name}/`hostname`_ovs_stats.log
  eval "sudo $1" | tee -a ${dir_name}/`hostname`_ovs_stats.log
}

ovs_clean "systemctl restart openvswitch.service; echo $?";
ovs_clean "ovs-appctl dpif-netdev/pmd-stats-clear";
ovs_clean "ovs-appctl dpctl/show -s";

DPDK0_DRP_CNT=$(ovs-appctl dpctl/show -s | grep -A4 dpdk1 | egrep dropped | grep RX | awk '{print $4}' | cut -d \: -f2)
DPDK1_DRP_CNT=$(ovs-appctl dpctl/show -s | grep -A4 dpdk2 | egrep dropped | grep RX | awk '{print $4}' | cut -d \: -f2)

ovs_dbg_on;
START=`date +%s`
while [ $(( $(date +%s) - 43200 )) -lt $START ]; do
    DPDK0_DRP_CNT_NEW=$(ovs-appctl dpctl/show -s | grep -A4 dpdk1 | egrep dropped | grep RX | awk '{print $4}' | cut -d \: -f2)
    DPDK1_DRP_CNT_NEW=$(ovs-appctl dpctl/show -s | grep -A4 dpdk2 | egrep dropped | grep RX | awk '{print $4}' | cut -d \: -f2)
	if [ $DPDK0_DRP_CNT_NEW -gt $DPDK0_DRP_CNT ] || [ $DPDK1_DRP_CNT_NEW -gt $DPDK1_DRP_CNT ]; then
		drp_counter "ovs-appctl dpctl/show -s | grep -A4 dpdk[12]";
		for i in 4 8 14 16; do drp_counter "ovs-appctl dpif-netdev/pmd-stats-show -pmd $i"; done;
		drp_counter "pidstat -t -p `pidof ovs-vswitchd`";
		drp_counter "ovs-appctl upcall/show";
		drp_counter "ovs-appctl coverage/show";
		ovs-appctl dpctl/dump-flows -m netdev@ovs-netdev |  tee -a ${dir_name}/`hostname`_dpdk_drop_netdev.log;
		archive_log;
		sos_report;
		ovs_dbg_off;
	exit 1;
	fi
	for i in 4 8 14 16; do ovs_stat "ovs-appctl dpif-netdev/pmd-stats-show -pmd $i"; done;
	ovs_stat "ovs-appctl upcall/show";
	ovs_stat "ovs-appctl coverage/show";
	ovs_stat "pidstat -t -p `pidof ovs-vswitchd`";
	ovs_stat "sleep 1m";
done
