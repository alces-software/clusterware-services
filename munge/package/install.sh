#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" ]]; then
  echo "MUNGE is not supported on el6"
  exit 1
elif [[ "$cw_DIST" == "el7" ]]; then
  yum install -y openssl
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y openssl libssl1.0.0
fi

cp -R data/opt "${cw_ROOT}"

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
  data/init/systemd/clusterware-slurm-munged.service \
  > /etc/systemd/system/clusterware-slurm-munged.service

# munged is fussy about these permissions
chmod g-w "${cw_ROOT}/opt/"

systemctl enable clusterware-slurm-munged.service

# Create MUNGE user and group.
getent group munge &>/dev/null || groupadd --gid 363 munge
getent passwd munge &>/dev/null || useradd --uid 363 --gid 363 \
  --shell /sbin/nologin --home-dir "${cw_ROOT}/opt/munge" munge

# MUNGE user needs to own this.
chown -R munge:munge "${cw_ROOT}/opt/munge/var"
