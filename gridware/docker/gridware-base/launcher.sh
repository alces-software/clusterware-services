#!/bin/bash -l

usage() {
    if [ -f /opt/gridware/etc/usage.md ]; then
        cat /opt/gridware/etc/usage.md
    else
        cat <<EOF
Usage: <command> [PARAMS...]

  e.g. alces gridware docker run apps-myapp-1.0 whoami

For more information please refer to the Alces Gridware website:
  https://gridware.alces-flight.com
EOF
    fi
}

_configure_sshd() {
  # Generate an SSH key for the server
  ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
  # Remove references to keys we've not generated
  sed -i -e "/ssh_host_e/d" /etc/ssh/sshd_config
}

if shopt -q login_shell; then
    if [ -f /opt/gridware/etc/defaults ]; then
        for a in $(cat /opt/gridware/etc/defaults); do
            module load $a
        done
    fi
fi


if [ -z "$1" ]; then
    if [ -x /opt/gridware/bin/default-cmd.sh ]; then
        exec /opt/gridware/bin/default-cmd.sh
    else
        echo "===>>> Alces Gridware <<<============================================="
        if [ -f /opt/gridware/etc/descriptor.txt ]; then
            DESC=$(cat /opt/gridware/etc/descriptor.txt)
            echo "$DESC"
            echo "======================================================================"
        fi
        echo ""
        usage
        echo ""
    fi
else
    if [[ "$1" == "--mpi" ]]; then
      _configure_sshd
      /usr/sbin/sshd -D
    elif [ -x "$1" -o -x "$(type -P "$1")" ]; then
        exec "$@"
    else
        echo "$1 not found. Did you mean '--script $@'?"
        exit 1
    fi
fi
