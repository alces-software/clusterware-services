#!/bin/bash

cp -pR data/* "${cw_ROOT}"

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring ephemeral disk configuration until next boot."
else
  "${cw_ROOT}/etc/handlers/configure-ephemeral-disks/configure"
fi
