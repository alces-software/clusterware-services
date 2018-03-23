#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el7" ]]; then
  yum install -e0 -y hwloc-libs postgresql-server libical
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y libhwloc5 postgresql libical1a libpython2.7
else
  echo "Unsupported distribution: ${cw_DIST}"
  exit 1
fi

if [ ! -d /var/spool/pbs ]; then
  mkdir /var/spool/pbs
  tar -C /var/spool/pbs -xzf data/pbspro-spool.tar.gz
fi

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
  data/init/systemd/clusterware-pbspro-comm.service \
  > /etc/systemd/system/clusterware-pbspro-comm.service

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
  data/init/systemd/clusterware-pbspro-server.service \
  > /etc/systemd/system/clusterware-pbspro-server.service

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
  data/init/systemd/clusterware-pbspro-sched.service \
  > /etc/systemd/system/clusterware-pbspro-sched.service
