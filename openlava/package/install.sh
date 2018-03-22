#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" ]]; then
  install_services() {
    for a in lim res sbatchd; do
      sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
        data/init/sysv/clusterware-openlava-$a.el6 \
        > /etc/init.d/clusterware-openlava-$a
      chmod 755 /etc/init.d/clusterware-openlava-$a
    done
  }
  yum install -y ncurses tcl
elif [[ "$cw_DIST" == "el7" ]]; then
  install_services() {
    for a in lim res sbatchd; do
      sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
        data/init/systemd/clusterware-openlava-$a.service \
        > /etc/systemd/system/clusterware-openlava-$a.service
    done
  }
  yum install -y ncurses tcl
elif [[ "$cw_DIST" == "ubuntu1604" || "$cw_DIST" == "el7" ]]; then
  install_services() {
    for a in lim res sbatchd; do
      sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
        data/init/systemd/clusterware-openlava-$a.service \
        > /etc/systemd/system/clusterware-openlava-$a.service
    done
  }
  apt-get install -y libncurses5 tcl
else
  echo "Unsupported distribution: ${cw_DIST}"
  exit 1
fi

cp -R data/etc "${cw_ROOT}"
cp -R data/opt "${cw_ROOT}"
cp -R data/var "${cw_ROOT}"

# install environment module
mkdir -p "${cw_ROOT}"/etc/modules/services
sed -e "s,_cw_ROOT_,${cw_ROOT},g" data/openlava-module.template > "${cw_ROOT}"/etc/modules/services/openlava

getent group openlava &>/dev/null || groupadd --gid 362 openlava
getent passwd openlava &>/dev/null || useradd --uid 362 --gid 362 \
  --shell /sbin/nologin --home-dir "${cw_ROOT}"/opt/openlava openlava

chown -R openlava:openlava "${cw_ROOT}"/opt/openlava

sed -e 's,^module load \(.*\),module load services/openlava \1,g' -i "${cw_ROOT}"/etc/skel/modules

install_services

mkdir -p /var/log/openlava
mkdir -p /var/spool/openlava/logdir
chown openlava /var/spool/openlava/logdir
