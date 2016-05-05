################################################################################
##
## Alces Clusterware - Clusterware MOTD banner
## Copyright (c) 2016 Stephen F. Norledge and Alces Software Ltd
##
################################################################################
if [[ :"$LOADEDMODULES": == *":services/aws:"* ]]; then
    echo ""
    printf "%-25s - %s\n" "'aws help'" "show help for AWS CLI"
fi
