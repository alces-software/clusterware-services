#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  yum install -y -e0 tcl
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y tcl
fi

cp -R data/* "${cw_ROOT}"

sed -i -e "s,_ROOT_,${cw_ROOT},g" "${cw_ROOT}/etc/modulerc/modulespath" \
  "${cw_ROOT}/etc/profile.d/09-modules.csh"
