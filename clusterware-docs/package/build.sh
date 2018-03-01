#!/bin/bash

package_name='clusterware-docs'
cw_ROOT=${cw_ROOT:-/opt/clusterware}

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

if command -v yum > /dev/null; then
  sudo yum install -y -e0 gmp-devel
elif command -v apt-get > /dev/null; then
  sudo apt-get -y -q install libgmp-dev
fi

cp -r * "${temp_dir}"

mkdir -p "${temp_dir}/data"
cp -r ../etc "${temp_dir}/data"
cp -r ../lib "${temp_dir}/data"
cp -r ../libexec "${temp_dir}/data"

pushd "${temp_dir}/data/opt/clusterware-docs" > /dev/null
  PATH="${cw_ROOT}"/opt/ruby/bin:$PATH
  bundle install --without="development test" --path=vendor
  rm -rf vendor/ruby/2.2.0/cache
popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
