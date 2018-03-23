#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el7" ]]; then
  yum install -e0 -y hwloc-libs
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y libhwloc5
else
  echo "Unsupported distribution: ${cw_DIST}"
  exit 1
fi

if [ ! -d /var/spool/pbs ]; then
  mkdir /var/spool/pbs
  tar -C /var/spool/pbs -xzf data/pbspro-spool.tar.gz
fi

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
  data/init/systemd/clusterware-pbspro-mom.service \
  > /etc/systemd/system/clusterware-pbspro-mom.service
