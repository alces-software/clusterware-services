#!/bin/bash

package_name='gridware'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

mkdir -p "${temp_dir}"/data/opt/clusterware/var/lib/docs/base

cp -Pr ../libexec "${temp_dir}"/data/opt/clusterware
cp -r ../etc "${temp_dir}"/data/opt/clusterware
cp -r ../docs/guides "${temp_dir}"/data/opt/clusterware/var/lib/docs/base/

cp -r ../dist "${temp_dir}"/data
cp -r ../docker "${temp_dir}"/data

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
