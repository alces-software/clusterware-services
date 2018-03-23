#!/bin/bash

package_name='pbspro-master'
cw_ROOT=${cw_ROOT:-/opt/clusterware}

yum install -e0 -y openssl-devel tcl-devel libXt-devel postgresql-devel \
      libedit-devel hwloc-devel libical-devel tk-devel python-devel

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
