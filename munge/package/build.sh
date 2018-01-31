#!/bin/bash

package_name='munge'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

sudo yum install -y openssl-devel

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"
mkdir -p "${temp_dir}"/data
cp -r ../init "${temp_dir}"/data

# Build MUNGE.
MUNGE_SOURCE='https://github.com/dun/munge/archive/munge-0.5.12.zip'
MUNGE_PATH="/opt/clusterware/opt/munge"
rm -rf "${MUNGE_PATH}" # Get rid of any old version of MUNGE so not building on top of.
curl -L "${MUNGE_SOURCE}" -o /tmp/munge.zip
unzip -d /tmp /tmp/munge.zip
pushd /tmp/munge-munge-* > /dev/null
./configure \
  --prefix="${MUNGE_PATH}" \
  --sysconfdir="${MUNGE_PATH}/etc" \
  --localstatedir="${MUNGE_PATH}/var"
make
sudo make install

popd > /dev/null

mkdir -p "${temp_dir}/data/opt"
sudo mv "${MUNGE_PATH}" "${temp_dir}/data/opt"

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

sudo rm -rf "${temp_dir}" /tmp/munge*
