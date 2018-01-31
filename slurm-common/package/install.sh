#!/bin/bash

cp -R data/opt "${cw_ROOT}"
cp -R data/etc "${cw_ROOT}"

# Create Slurm user and group.
getent group slurm &>/dev/null || groupadd --gid 364 slurm
getent passwd slurm &>/dev/null || useradd --uid 364 --gid 364 \
  --shell /sbin/nologin --home-dir "${cw_ROOT}/opt/slurm" slurm

# Copy Slurm config.
mkdir -p "${cw_ROOT}/opt/slurm/etc"
cp data/slurm.conf.template "${cw_ROOT}/opt/slurm/etc/slurm.conf"

# Install Slurm MOTD.
cp data/motd.sh "${cw_ROOT}"/etc/motd.d/00-tips-10-slurm.sh

# Install environment module (we also add it to the skeleton modules file
# so it will be automatically loaded for Clusterware users created after
# installing Slurm).
mkdir -p "${cw_ROOT}"/etc/modules/services
sed -e "s,_cw_ROOT_,${cw_ROOT},g" data/slurm-module.template > "${cw_ROOT}"/etc/modules/services/slurm
sed -e 's,^module load \(.*\),module load services/slurm \1,g' -i "${cw_ROOT}"/etc/skel/modules

mkdir -p "${cw_ROOT}"/var/lib/docs/slurm
cp -R data/docs/templates "${cw_ROOT}"/var/lib/docs/slurm
cp -R data/docs/guides "${cw_ROOT}"/var/lib/docs/slurm

mkdir -p "${cw_ROOT}"/var/lib/scheduler
cp data/slurm.functions.sh "${cw_ROOT}"/var/lib/scheduler
