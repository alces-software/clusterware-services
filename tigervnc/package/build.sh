#!/bin/bash

package_name='tigervnc'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"
mkdir -p "${temp_dir}/data"

# TODO: Build TigerVNC from source rather than crib the existing Clusterware build of it

pushd "$temp_dir/data" > /dev/null

  curl -o tigervnc.tar.gz "https://s3-eu-west-1.amazonaws.com/packages.alces-software.com/clusterware/dist/el7/tigervnc.tar.gz"
  tar -xvf tigervnc.tar.gz
  rm tigervnc.tar.gz

popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
