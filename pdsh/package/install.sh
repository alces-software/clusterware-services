#!/bin/bash

cp -R data/opt "${cw_ROOT}"
cp data/motd.sh "${cw_ROOT}"/etc/motd.d/00-tips-40-pdsh.sh

sed -e "s,_cw_ROOT_,${cw_ROOT},g" data/pdsh-module.template > "${cw_ROOT}"/etc/modules/services/pdsh
