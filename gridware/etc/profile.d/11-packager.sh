################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2008-2016 Alces Software Ltd
##
################################################################################
for a in modules modulerc; do
    if [ ! -f "$HOME/.$a" ]; then
        sed -e "s#%NULL_MODULE_PATH%#$(_cw_root)/etc/modules/#" "$(_cw_root)"/etc/skel/$a > "$HOME/.$a"
    fi
done
unset a

allow_users="$(cd $(_cw_root); bash -c 'source etc/gridware.rc 2> /dev/null && echo ${cw_GRIDWARE_allow_users}')"
if [ "${allow_users}" != "false" ]; then
    if [ ! -d ~/gridware/personal ] && [ $UID -ne 0 ] && [ -d /opt/gridware ]; then
        pushd ~ >/dev/null 2>&1
        "$(_cw_root)/bin/alces" gridware init
        popd >/dev/null 2>&1
    fi
fi
unset allow_users

    _alces_gridware_list() {
        "$(_cw_root)"/bin/alces gridware list 2>&1 | sed '
                s#^\(.*\)/\(.\+\)(default)#\1\n\1\/\2#;
                s#/*$##g; s#^base/##g;'
    }

    _alces_gridware_depot_list() {
        "$(_cw_root)"/bin/alces gridware depot list -1 2>&1 | sed '
                s#^\(.*\)/\(.\+\)(default)#\1\n\1\/\2#;
                s#/*$##g; s#^base/##g;'

    }

    _alces_list_cache_expired() {
        local mtime
        mtime=$1
        if (($(date +%s)-$mtime > 60)); then
            return 0
        else
            return 1
        fi
    }

    _alces_gridware() {
        local cur="$1" prev="$2" cmds opts
        cmds="clean default dependencies docker help info install list purge update import export depot search requires requests"
        if ((COMP_CWORD > 2)); then
            case "$prev" in
                reque*)
                    COMPREPLY=( $(compgen -W "list install" -- "$cur") )
                    ;;
                in*|r*)
                    if ((COMP_CWORD > 3)); then
                      if [ -z "$cw_DEPOT_LIST" ] || _alces_list_cache_expired $cw_DEPOT_LIST_MTIME; then
                        cw_DEPOT_LIST=$(_alces_gridware_depot_list)
                        cw_DEPOT_LIST_MTIME=$(date +%s)
                      fi
                      COMPREPLY=( $(compgen -W "$cw_DEPOT_LIST" -- "$cur") )
                    else
                      if [ -z "$cw_PACKAGE_LIST" ] || _alces_list_cache_expired $cw_PACKAGE_LIST_MTIME; then
                          cw_PACKAGE_LIST=$(_alces_gridware_list)
                          cw_PACKAGE_LIST_MTIME=$(date +%s)
                      fi
                      COMPREPLY=( $(compgen -W "$cw_PACKAGE_LIST" -- "$cur") )
                    fi
                    ;;
                p*|c*|def*|e*|l*)
                    # for purge, clean and default, we provide a module list
                    COMPREPLY=( $(compgen -W "$(_module_avail_specific)" -- "$cur") )
                    ;;
                depo*)
                    COMPREPLY=( $(compgen -W "list enable disable update info install purge init" -- "$cur") )
                    ;;
                do*)
                   COMPREPLY=( $(compgen -W "build help list pull push run share start-registry" -- "$cur") )
                    ;;
                *)
                    # for purge, clean and default, we provide a module list
                    COMPREPLY=( $(compgen -f -- "$cur") )
                    ;;
            esac
        else
            case "$prev" in
                *)
                    COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
                    ;;
            esac
        fi
    }
fi
