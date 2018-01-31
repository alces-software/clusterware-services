#!/bin/bash

package_name='openvpn'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"
mkdir -p "${temp_dir}/data/opt"
cp -r ../init "${temp_dir}/data"

sudo yum install -y openssl-devel net-tools lzo-devel pam-devel

curl -L "https://swupdate.openvpn.org/community/releases/openvpn-2.3.10.tar.gz" -o /tmp/openvpn-source.tar.gz
tar -C /tmp -xzf "/tmp/openvpn-source.tar.gz"
pushd /tmp/openvpn-2.3.10 > /dev/null
# This does want to be /opt/clusterware - since this path gets included in various compiled binaries :(
./configure --prefix=/opt/clusterware/opt/openvpn
make
make install

popd > /dev/null

mv /opt/clusterware/opt/openvpn "${temp_dir}/data/opt"

rm -rf /tmp/openvpn-*

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
