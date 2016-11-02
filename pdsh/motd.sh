################################################################################
##
## Alces Clusterware - Clusterware MOTD banner
## Copyright (c) 2016 Stephen F. Norledge and Alces Software Ltd
##
################################################################################
if [[ :"$LOADEDMODULES": == *":services/pdsh:"* ]]; then
    echo ""
    printf "%-25s - %s\n" "'pdsh --help'" "show help for pdsh"
fi
