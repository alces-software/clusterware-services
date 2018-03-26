#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" != "el7" ]]; then
  echo "Unsupported distribution: ${cw_DIST}"
  exit 1
fi

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
  data/init/systemd/clusterware-torque-server.service \
  > /etc/systemd/system/clusterware-torque-server.service

name="$(hostname -f)"
echo "${name}" > /var/spool/torque/server_name

systemctl start clusterware-torque-trqauthd

LD_LIBRARY_PATH="${cw_ROOT}"/opt/torque/lib:$LD_LIBRARY_PATH
PATH="${cw_ROOT}"/opt/torque/sbin:"${cw_ROOT}"/opt/torque/bin:$PATH
pbs_server -t create -f
sleep 2
echo set server operators += root@${name} | qmgr
echo set server managers += root@${name} | qmgr
qmgr -c 'set server scheduling = true'
qmgr -c 'set server keep_completed = 300'
qmgr -c 'set server mom_job_sync = true'
qmgr -c 'create queue batch'
qmgr -c 'set queue batch queue_type = execution'
qmgr -c 'set queue batch started = true'
qmgr -c 'set queue batch enabled = true'
qmgr -c 'set queue batch resources_default.walltime = 1:00:00'
qmgr -c 'set queue batch resources_default.nodes = 1'
qmgr -c 'set server default_queue = batch'
qterm

systemctl stop clusterware-torque-trqauthd

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
  data/init/systemd/clusterware-torque-sched.service \
  > /etc/systemd/system/clusterware-torque-sched.service
