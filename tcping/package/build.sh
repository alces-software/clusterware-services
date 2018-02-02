#!/bin/bash

package_name='tcping'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

sudo yum install -y -e0 glibc-static

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp install.sh metadata.json "${temp_dir}"

mkdir -p "${temp_dir}/data/opt/tcping/"{bin,doc}

curl -L "https://github.com/alces-software/tcping/archive/master.zip" -o /tmp/tcping-source.zip

unzip -d /tmp /tmp/tcping-source.zip
pushd /tmp/tcping-* > /dev/null

gcc -o tcping -Wall -DHAVE_HSTRERROR tcping.c -static
strip tcping
cp tcping "${temp_dir}"/data/opt/tcping/bin
cp README.md LICENSE "${temp_dir}"/data/opt/tcping/doc

popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}" /tmp/tcping*
