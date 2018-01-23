#!/bin/bash

package_name='serf'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

curl -L "https://releases.hashicorp.com/serf/0.6.4/serf_0.6.4_linux_amd64.zip" \
  -o /tmp/serf-source.zip

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

mkdir -p "${temp_dir}/data/opt/serf/bin"
unzip -d "${temp_dir}/data/opt/serf/bin" "/tmp/serf-source.zip"

rm "/tmp/serf-source.zip"

cp -r * "${temp_dir}"

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
