#!/bin/bash

package_name='torque-common'
cw_ROOT=${cw_ROOT:-/opt/clusterware}

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

yum install -e0 -y gcc-c++ openssl-devel libxml2-devel boost-devel gperf pam-devel

curl -L http://wpfilebase.s3.amazonaws.com/torque/torque-6.0.1-1456945733_daea91b.tar.gz -o /tmp/torque.tar.gz
tar -C /tmp -xzf /tmp/torque.tar.gz
patch=$(pwd)/../pbs_sched-bind.patch
pushd /tmp/torque-* > /dev/null
patch -p0 < "${patch}"
./configure --prefix="${cw_ROOT}"/opt/torque \
  --with-pam \
  --enable-drmaa \
  --with-default-server=master
make
make install
popd > /dev/null

mkdir -p "${temp_dir}"/data/opt
mv "${cw_ROOT}"/opt/torque "${temp_dir}"/data/opt

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
