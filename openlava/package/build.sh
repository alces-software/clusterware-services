#!/bin/bash

package_name='openlava-common'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

# OpenLava was killed by IBM, so the source code is no longer available. We'll have to make do with
# the existing Clusterware binary build.
curl -o /tmp/openlava.tar.gz "https://s3-eu-west-1.amazonaws.com/packages.alces-software.com/clusterware/dist/el7/openlava.tar.gz"
tar -C "${temp_dir}"/data -xf /tmp/openlava.tar.gz
rm /tmp/openlava.tar.gz

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
