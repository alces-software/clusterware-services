#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" != "el7" ]]; then
  echo "Unsupported distribution: ${cw_DIST}"
  exit 1
fi

if [ ! -d /var/spool/torque ]; then
  mkdir /var/spool/torque
  tar -C /var/spool/torque -xzf data/torque-spool.tar.gz
fi

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
  data/init/systemd/clusterware-torque-trqauthd.service \
  > /etc/systemd/system/clusterware-torque-trqauthd.service
