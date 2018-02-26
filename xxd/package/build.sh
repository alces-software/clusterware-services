#!/bin/bash

package_name='xxd'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

curl -L "https://github.com/ThatOtherPerson/xxd/archive/master.zip" -o /tmp/xxd.zip

unzip -d /tmp /tmp/xxd.zip
pushd /tmp/xxd-master > /dev/null

make

mkdir -p "${temp_dir}"/data/opt/xxd/{bin,man/man1}

cp xxd "${temp_dir}"/data/opt/xxd/bin
cp xxd.1 "${temp_dir}"/data/opt/xxd/man/man1

popd > /dev/null

rm -rf /tmp/xxd*

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
