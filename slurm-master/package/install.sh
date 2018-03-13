#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" ]]; then
  echo "Slurm is not supported on EL6"
  exit 1
fi

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
    data/init/systemd/clusterware-slurm-slurmctld.service \
    > /etc/systemd/system/clusterware-slurm-slurmctld.service
cat <<EOF > /etc/tmpfiles.d/clusterware-slurm.conf
# Clusterware Slurm runtime directory
d /run/slurm 0755 slurm root -
EOF

systemctl enable clusterware-slurm-slurmctld.service
