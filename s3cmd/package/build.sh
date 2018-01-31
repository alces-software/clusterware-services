#!/bin/bash

package_name='s3cmd'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

mkdir "${temp_dir}/data"
cp ../motd.sh ../s3cmd-module.template "${temp_dir}/data"

curl -L "https://github.com/s3tools/s3cmd/releases/download/v2.0.1/s3cmd-2.0.1.tar.gz" -o /tmp/s3cmd-source.tar.gz
tar -C /tmp -xzf "/tmp/s3cmd-source.tar.gz"

pushd /tmp/s3cmd-*

mkdir -p "${temp_dir}/data/opt/s3cmd"/{doc,man/man1}
cp -R s3cmd S3 "${temp_dir}/data/opt/s3cmd"
cp README.md "${temp_dir}/data/opt/s3cmd/doc"
cp s3cmd.1 "${temp_dir}/data/opt/s3cmd/man/man1"

popd

rm -rf /tmp/s3cmd-*


pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
