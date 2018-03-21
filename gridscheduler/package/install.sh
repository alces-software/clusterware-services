#!/bin/bash

cp -R data/libexec "${cw_ROOT}"
cp -R data/opt "${cw_ROOT}"
cp -R data/var "${cw_ROOT}"

if [ -f "${cw_ROOT}"/opt/gridscheduler/etc/common/host_aliases ]; then
  mv "${cw_ROOT}"/opt/gridscheduler/etc/common/host_aliases "${cw_ROOT}"/opt/gridscheduler/etc/common/host_aliases.disabled
fi

getent group geadmin &>/dev/null || groupadd --gid 360 geadmin
getent passwd geadmin &>/dev/null || useradd --uid 360 --gid 360 \
    --shell /sbin/nologin --home-dir "${cw_ROOT}"/opt/gridscheduler geadmin

# install environment module
mkdir -p "${cw_ROOT}"/etc/modules/services
sed -e "s,_cw_ROOT_,${cw_ROOT},g" data/gridscheduler-module.template > "${cw_ROOT}"/etc/modules/services/gridscheduler

cp data/qdesktop "${cw_ROOT}"/opt/gridscheduler/bin/linux-x64
# install qdesktop configuration file
if [ ! -f "${cw_ROOT}"/etc/qdesktop.rc ]; then
    cp data/qdesktop.rc "${cw_ROOT}"/etc/qdesktop.rc
fi

cp data/motd.sh "${cw_ROOT}"/etc/motd.d/00-tips-10-gridscheduler.sh

sed -e 's,^module load \(.*\),module load services/gridscheduler \1,g' -i "${cw_ROOT}"/etc/skel/modules

mkdir -p "${cw_ROOT}"/var/lib/scheduler
