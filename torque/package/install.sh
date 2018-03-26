#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  yum install -e0 -y openssl libxml2
else
  echo "Unsupported distribution: ${cw_DIST}"
  exit 0
fi

cp -R data/etc "${cw_ROOT}"
cp -R data/opt "${cw_ROOT}"
cp -R data/var "${cw_ROOT}"

# Install environment module (we also add it to the skeleton modules file
# so it will be automatically loaded for Clusterware users created after
# installing Torque).
mkdir -p "${cw_ROOT}"/etc/modules/services
sed -e "s,_cw_ROOT_,${cw_ROOT},g" data/torque-module.template > "${cw_ROOT}"/etc/modules/services/torque
sed -e 's,^module load \(.*\),module load services/torque \1,g' -i "${cw_ROOT}"/etc/skel/modules
