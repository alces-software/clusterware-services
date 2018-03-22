#!/bin/bash

package_name='swapspace'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

curl -L "http://pqxx.org/download/software/swapspace/swapspace-1.10.tar.gz" -o /tmp/swapspace-source.tar.gz
tar -C /tmp -xzf "/tmp/swapspace-source.tar.gz"

pushd /tmp/swapspace-* > /dev/null
sed -i -e 's/VERSION DATE//g' Makefile
make
mkdir -p "${temp_dir}"/data/opt/swapspace/{bin,doc,etc}
cp src/swapspace src/hog "${temp_dir}"/data/opt/swapspace/bin
cp COPYING README "${temp_dir}"/data/opt/swapspace/doc
cp swapspace.conf "${temp_dir}"/data/opt/swapspace/etc

popd > /dev/null
rm -rf /tmp/swapspace-*

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
