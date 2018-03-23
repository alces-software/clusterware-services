#!/bin/bash

package_name='pbspro-common'
cw_ROOT=${cw_ROOT:-/opt/clusterware}

yum install -e0 -y openssl-devel tcl-devel libXt-devel postgresql-devel \
      libedit-devel hwloc-devel libical-devel tk-devel python-devel

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

curl -L https://github.com/PBSPro/pbspro/archive/v14.1.0.tar.gz -o /tmp/pbspro.tar.gz
tar -C /tmp/ -xzf /tmp/pbspro.tar.gz

#if [ "$cw_DIST" == "ubuntu1604" ]; then
#  patch -d /tmp/pbspro-* -p1 < ubuntu-compat.patch
#  pushd /tmp/pbspro-*
#  ./autogen.sh
#else

pushd /tmp/pbspro-*

#fi

./configure --prefix="${cw_ROOT}"/opt/pbspro \
  --with-pbs-conf-file="${cw_ROOT}"/opt/pbspro/pbs.conf "${build_args[@]}"
make
make install
popd

chmod 4755 "${cw_ROOT}"/opt/pbspro/sbin/pbs_iff "${cw_ROOT}"/opt/pbspro/sbin/pbs_rcp

mv "${cw_ROOT}"/opt "${temp_dir}"/data

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
