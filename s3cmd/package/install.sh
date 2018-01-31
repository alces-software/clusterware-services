#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  yum -e0 -y install python-dateutil python-magic
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y python-dateutil python-magic
fi

cp -R data/opt "${cw_ROOT}"
mkdir -p "${cw_ROOT}"/etc/modules/services
sed -e "s,_cw_ROOT_,${cw_ROOT},g" data/s3cmd-module.template > "${cw_ROOT}"/etc/modules/services/s3cmd
sed -e 's,^module load \(.*\),module load services/s3cmd \1,g' -i "${cw_ROOT}"/etc/skel/modules
cp data/motd.sh "${cw_ROOT}"/etc/motd.d/00-tips-20-s3cmd.sh
