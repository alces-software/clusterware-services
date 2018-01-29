#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  #yum install -y -e0 <RPM dependencies>
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  #apt-get install -y <DEB dependencies>
fi

cp -R data/* "${cw_ROOT}"
