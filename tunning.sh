
## This bash is designed for VM where the VM has spawnned in Real time KVM host. This script helps 
## to configured the pre-requisite configuration like, isolcpus, hugepages and tuned real-time profile

#/bin/bash
# choose these values according to your hardware specs

KERNEL_ARGS="isolcpus=2-3 default_hugepagesz=1GB hugepagesz=1G hugepages=4 iommu=pt intel_iommu=on intel_pstate=disable nosoftlockup"
TUNED_CORES="2,3"

rpm  -ivh http://************/pub/katello-ca-consumer-latest.noarch.rpm 
subscription-manager register --org="****" --activationkey="****" --force
subscription-manager repos --disable=* --enable=rhel-7-server-rh-common-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-openstack-14-rpms --enable=rhel-7-server-nfv-rpms --enable=rhel-7-server-rpms 


# Install the tuned package
yum install -y kernel-rt qemu-kvm tuned tuned-profiles-realtime tuned-profiles-nfv rt-tests

tuned_conf_path="/etc/tuned/realtime-virtual-guest-variables.conf"
if [ -n "$TUNED_CORES" ]; then
  grep -q "^isolated_cores" $tuned_conf_path
  if [ "1" -eq 0 ]; then
    sed -i 's/^isolated_cores=.*/isolated_cores=$TUNED_CORES/' $tuned_conf_path
  else
    echo "isolated_cores=$TUNED_CORES" >> $tuned_conf_path
  fi
  tuned-adm profile realtime-virtual-guest
fi

sed -i 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 '"$KERNEL_ARGS"'"/g'  /etc/default/grub
grub2-mkconfig -o /etc/grub2.cfg
