#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" ]]; then
  enable_swapspace() {
    sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
      data/init/sysv/clusterware-swapspace.el6 \
      > /etc/init.d/clusterware-swapspace
    chmod 755 /etc/init.d/clusterware-swapspace
    chkconfig clusterware-swapspace on
  }
elif [[ "$cw_DIST" == "ubuntu1604" || "$cw_DIST" == "el7" ]]; then
  enable_swapspace() {
    sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
      data/init/systemd/clusterware-swapspace.service \
      > /etc/systemd/system/clusterware-swapspace.service
    systemctl enable clusterware-swapspace.service
  }
fi

cp -R data/opt "${cw_ROOT}"

mkdir -p /var/lib/swapspace
chmod 0700 /var/lib/swapspace

enable_swapspace
