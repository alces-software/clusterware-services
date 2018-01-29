#!/bin/bash
require files
files_load_config distro

cp -pR data/* "${cw_ROOT}"

mkdir -p "${cw_ROOT}"/opt/clusterware-config
