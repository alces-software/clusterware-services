#!/bin/bash

package_name='slurm-common'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/forge-${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

# Build Slurm.
SLURM_SOURCE='https://github.com/SchedMD/slurm/archive/slurm-16-05-0-1.zip'
SLURM_PATH="/opt/clusterware/opt/slurm"
curl -L "${SLURM_SOURCE}" -o /tmp/slurm.zip
unzip -d /tmp /tmp/slurm.zip
pushd /tmp/slurm-slurm-* > /dev/null
./configure \
  --prefix="${SLURM_PATH}" \
  --with-munge="/opt/clusterware/opt/munge"
make
sudo make install
popd > /dev/null

mkdir -p "${temp_dir}"/data/opt
sudo mv "${SLURM_PATH}" "${temp_dir}"/data/opt

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

sudo rm -rf "${temp_dir}" /tmp/slurm*
