#!/bin/bash

if ! grep -q 'account \[default=ignore success=1\] pam_succeed_if.so quiet user ingroup adm' /etc/pam.d/sshd; then
  sed -i '/^account\s*required\s*pam_nologin.so/i account [default=ignore success=1] pam_succeed_if.so quiet user ingroup adm' \
    /etc/pam.d/sshd
fi
