#!/bin/bash

if [ -f modules.zip ]; then
  rm modules.zip
fi

temp_dir=$(mktemp -d /tmp/gridware-build-XXXXX)

mkdir "${temp_dir}/data"
cp -r * "${temp_dir}"
cp -r ../etc "${temp_dir}/data"

pushd "$temp_dir/data" > /dev/null

  curl -o modules.tar.gz "https://s3-eu-west-1.amazonaws.com/packages.alces-software.com/clusterware/dist/el7/modules-20161031-cw1_7.tar.gz"
  tar -xvf modules.tar.gz
  rm modules.tar.gz

popd > /dev/null

pushd "$temp_dir" > /dev/null

  zip -r modules.zip *

popd > /dev/null

mv "${temp_dir}/modules.zip" .

rm -rf "${temp_dir}"
