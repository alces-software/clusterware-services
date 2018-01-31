#!/bin/bash

cp -R data/* "${cw_ROOT}"
mkdir -p "${cw_ROOT}"/opt/clusterware-ssl

chmod 0600 "${cw_ROOT}"/etc/naming.rc
