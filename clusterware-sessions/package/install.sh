#!/bin/bash

cp -R data/* "${cw_ROOT}"

mkdir -p "${cw_ROOT}"/opt/clusterware-sessions

echo "Setting up session base repository"
if [ -d "${cw_ROOT}/var/lib/sessions/repos" ]; then
  echo 'Detected existing repository.'
else
  echo 'Initializing repository:'
  if [ -f /tmp/clusterware-sessions.tar.gz ]; then
    mkdir -p "${cw_ROOT}"/var/lib/sessions/repos/base
    tar -C "${cw_ROOT}"/var/lib/sessions/repos/base -xzf /tmp/clusterware-sessions.tar.gz
  else
    export cw_SESSION_rev cw_SESSION_track
    "${cw_ROOT}/bin/alces" session update
    "${cw_ROOT}/bin/alces" session enable default
  fi
fi
