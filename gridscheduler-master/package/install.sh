#!/bin/bash

set +e
_ALCES="${cw_ROOT}"/bin/alces

require files
files_load_config distro

if [[ "$cw_DIST" == "el6" ]]; then
  enable_qmaster() {
    sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
      data/init/sysv/clusterware-gridscheduler-qmaster.el6 \
      > /etc/init.d/clusterware-gridscheduler-qmaster
    chmod 755 /etc/init.d/clusterware-gridscheduler-qmaster
    chkconfig clusterware-gridscheduler-qmaster on
  }

  start_qmaster() {
    service clusterware-gridscheduler-qmaster start
  }

  restart_qmaster() {
    service clusterware-gridscheduler-qmaster stop
    service clusterware-gridscheduler-qmaster start
  }
elif [[ "$cw_DIST" == "el7" || "$cw_DIST" == "ubuntu1604" ]]; then
  enable_qmaster() {
    sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
      data/init/systemd/clusterware-gridscheduler-qmaster.service \
      > /etc/systemd/system/clusterware-gridscheduler-qmaster.service
    systemctl enable clusterware-gridscheduler-qmaster.service
  }

  start_qmaster() {
    systemctl start clusterware-gridscheduler-qmaster.service
  }

  restart_qmaster() {
    systemctl restart clusterware-gridscheduler-qmaster.service
  }
fi

tmr=0
hn=$(hostname -f)
while [ -z "$hn" -a $tmr -lt 10 ]; do
  tmr=$(($tmr+1))
  sleep 1
  hn=$(hostname -f)
done
if [ -z "$hn" ]; then
  echo "Unable to determine hostname."
  exit 1
fi

$_ALCES module purge
$_ALCES module use "${cw_ROOT}"/etc/modules
$_ALCES module load services/gridscheduler

PATH=$PATH:${GRIDSCHEDULERBIN}  # Not sure why module doesn't do this for us...

# unpack /var/spool/gridscheduler
tar -C / -xzf data/var-spool-gridscheduler.tar.gz

arch=$($SGE_ROOT/util/arch)
$SGE_ROOT/utilbin/$arch/spoolinit classic libspoolc \
  "${cw_ROOT}/opt/gridscheduler/etc/conf;/var/spool/gridscheduler/qmaster" init

chown geadmin:geadmin -R /var/spool/gridscheduler
chown geadmin:geadmin -R "${cw_ROOT}"/opt/gridscheduler/etc
echo "$hn" > "${cw_ROOT}"/opt/gridscheduler/etc/common/act_qmaster
echo 'geadmin' >> /var/spool/gridscheduler/qmaster/managers

# install qmaster init script/unit
enable_qmaster
# start up qmaster so we can configure it
start_qmaster

# wait for startup
c=0
while [ $c -lt 30 ] && ! qconf -sm &> /dev/null; do
  sleep 1
  c=$(($c+1))
done

qconf -as $hn

for a in data/templates/hostgroup/*; do
  qconf -Ahgrp $a || qconf -Mhgrp $a
done

for a in data/templates/pe/*; do
  qconf -Ap $a || qconf -Mp $a
done

for a in data/templates/queue/*; do
  qconf -Aq $a || qconf -Mq $a
done

for a in data/templates/project/*; do
  qconf -Aprj $a || qconf -Mprj $a
done

#make queues subordinate each other
qconf -mattr queue subordinate_list 'bynode.q=1' byslot.q
qconf -mattr queue subordinate_list 'byslot.q=1' bynode.q

echo "-w w -j y -p -100 -l h_rt=24:0:0" >> "${SGE_ROOT}"/etc/conf/sge_request

qconf -Mc data/templates/complex_attributes
qconf -Mrqs data/templates/resource_quota_sets
qconf -Msconf data/templates/scheduler_configuration

sed -e 's/^\(auto_user_default_project.*\)none/\1default.prj/g' \
  -i "${SGE_ROOT}"/etc/conf/configuration

restart_qmaster
