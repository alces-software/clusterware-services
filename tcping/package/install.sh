#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  yum install -y -e0 glibc-static
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y libc6-dev
fi

cp -R data/* "${cw_ROOT}"
