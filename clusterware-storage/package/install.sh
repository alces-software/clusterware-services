#!/bin/bash

cp -R data/* "${cw_ROOT}"

rm -f "${cw_ROOT}"/etc/storage/.gitkeep
mkdir -p "${cw_ROOT}"/opt/clusterware-storage

echo "Setting up storage base repository"
if [ -d "${cw_ROOT}/var/lib/storage/repos" ]; then
    echo 'Detected existing repository.'
else
  echo 'Initializing repository:'
  if [ -f /tmp/clusterware-storage.tar.gz ]; then
    mkdir -p "${cw_ROOT}"/var/lib/storage/repos/base
    tar -C "${cw_ROOT}"/var/lib/storage/repos/base -xzf /tmp/clusterware-storage.tar.gz
  else
    require files
    files_load_config serviceware
    export cw_STORAGE_rev cw_STORAGE_track
    "${cw_ROOT}/bin/alces" storage update
  fi
fi
