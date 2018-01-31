#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  yum install -y openssl net-tools lzo-minilzo
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y openssl libssl1.0.0 net-tools liblzo2-2
fi

cp -R data/opt "${cw_ROOT}"

case "$cw_DIST" in
  "(el7|ubuntu1610)")
    sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
      data/init/systemd/clusterware-openvpn@.service \
      > /etc/systemd/system/clusterware-openvpn@.service
    mkdir -p /run/clusterware-openvpn
    cat <<EOF > /etc/tmpfiles.d/clusterware-openvpn.conf
# Clusterware OpenVPN runtime directory
d /run/clusterware-openvpn 0755 root root -
EOF
  ;;
  "el6")
    sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
      data/init/sysv/clusterware-openvpn.el6 \
      > /etc/init.d/clusterware-openvpn
    chmod 755 /etc/init.d/clusterware-openvpn
  ;;
esac

mkdir -p "${cw_ROOT}"/etc/openvpn
