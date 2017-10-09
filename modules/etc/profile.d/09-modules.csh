################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2008-2016 Alces Software Ltd
##
################################################################################
alias | grep "^module\b" > /dev/null
if ( $? == 1 ) then
    foreach a ( modules )
      if ( ! -f "$HOME/.$a" ) then
          sed -e "s#%NULL_MODULE_PATH%#$(_cw_root)/etc/modules/#" _ROOT_/etc/skel/$a > "$HOME/.$a"
      endif
    end

    if ($?tcsh) then
        set modules_shell="tcsh"
    else
        set modules_shell="csh"
    endif
    set exec_prefix='_ROOT_/opt/modules/bin'

    set prefix=""
    set postfix=""

    if ( $?histchars ) then
        set histchar = `echo $histchars | cut -c1`
        set _histchars = $histchars

        set prefix  = 'unset histchars;'
        set postfix = 'set histchars = $_histchars;'
    else
        set histchar = \!
    endif

    if ($?prompt) then
        set prefix  = "$prefix"'set _prompt="$prompt";set prompt="";'
        set postfix = "$postfix"'set prompt="$_prompt";unset _prompt;'
    endif

    if ($?noglob) then
        set prefix  = "$prefix""set noglob;"
        set postfix = "$postfix""unset noglob;"
    endif
    set postfix = "set _exit="'$status'"; $postfix; test 0 = "'$_exit;'

    alias module $prefix'eval `'$exec_prefix'/modulecmd '$modules_shell' '$histchar'*`; '$postfix
    unset exec_prefix
    unset prefix
    unset postfix

    if (! $?MODULEPATH ) then
        setenv MODULEPATH `sed -n 's/[        #].*$//; /./H; $ { x; s/^\n//; s/\n/:/g; p; }' _ROOT_/etc/modulerc/modulespath`
    endif

    if (! $?LOADEDMODULES ) then
        setenv LOADEDMODULES ""
    endif

    #source modules file from home dir
    if ( -r ~/.modules ) then
      source ~/.modules
    endif
endif
