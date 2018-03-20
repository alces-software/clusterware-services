#!/bin/bash

set +e

require files
files_load_config distro

if [[ "$cw_DIST" == "el6" ]]; then
  enable_execd() {
    sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
      data/init/sysv/clusterware-gridscheduler-execd.el6 \
      > /etc/init.d/clusterware-gridscheduler-execd
    chmod 755 /etc/init.d/clusterware-gridscheduler-execd
    chkconfig clusterware-gridscheduler-execd on
  }
elif [[ "$cw_DIST" == "el7" || "$cw_DIST" == "ubuntu1604" ]]; then
  enable_execd() {
    sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
      data/init/systemd/clusterware-gridscheduler-execd.service \
      > /etc/systemd/system/clusterware-gridscheduler-execd.service
    systemctl enable clusterware-gridscheduler-execd.service
  }
fi

mkdir -p /var/spool/gridscheduler
chown geadmin:geadmin /var/spool/gridscheduler

cat << EOF > /etc/security/limits.d/99-clusterware-80-gridscheduler.conf
################################################################################
##
## Alces Clusterware - System configuration
## Copyright (c) 2015 Alces Software Ltd
##
################################################################################
# Allow all users to lock all memory
* soft memlock unlimited
* hard memlock unlimited
EOF

enable_execd
