#!/bin/sh

cp -r data/etc "${cw_ROOT}"
cp -r data/lib "${cw_ROOT}"
cp -r data/libexec "${cw_ROOT}"

require files
files_load_config distro

case "$cw_DIST" in
  "el6")
    for a in "data/dist/init/sysv"/*.el6; do
        target_init_script="$(basename "$a" .el6)"
        if [ "${target_init_script##*.}" == 'inactive' ]; then
          cp $a /etc/init.d/$(basename "${target_init_script}" .inactive) && \
            chmod 755 /etc/init.d/$(basename "${target_init_script}" .inactive) || \
            return 1
        else
          cp $a /etc/init.d/${target_init_script} && \
            chmod 755 /etc/init.d/${target_init_script} && \
            chkconfig "${target_init_script}" on || \
            return 1
        fi
    done
;;
  "el7"|"ubuntu1604")
  for a in "dist/init/systemd"/*; do
    if [ "${a##*.}" == 'inactive' ]; then
      cp $a /etc/systemd/system/$(basename "$a" .inactive) || return 1
    else
      cp $a /etc/systemd/system && \
          systemctl enable "$(basename $a)" || \
          return 1
    fi
  done
;;
esac
