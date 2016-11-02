################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2008-2016 Alces Software Ltd
##
################################################################################
if ! type module &>/dev/null; then
    module() { eval `$(_cw_root)/opt/modules/bin/modulecmd bash $*`; }
    export -f module

    if [ "${LOADEDMODULES:-}" = "" ]; then
        LOADEDMODULES=
        export LOADEDMODULES
    fi

    if [ "${MODULEPATH:-}" = "" ]; then
        MODULEPATH=`sed -n 's/[       #].*$//; /./H; $ { x; s/^\n//; s/\n/:/g; p; }' "$(_cw_root)"/etc/modulerc/modulespath`
        export MODULEPATH
    fi

    if [ ${BASH_VERSINFO:-0} -ge 3 ] && [ -r "$(_cw_root)"/opt/modules/init/bash_completion ]; then
        . "$(_cw_root)"/opt/modules/init/bash_completion
    fi
fi
