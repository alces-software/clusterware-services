################################################################################
##
## Alces Clusterware - Clusterware MOTD banner script
## Copyright (c) 2016 Stephen F. Norledge and Alces Software Ltd
##
################################################################################
if [[ :"$LOADEDMODULES": == *":services/openlava:"* ]]; then
    echo ""
    printf "%-25s - %s\n" "'bsub'" "submit a job script"
    printf "%-25s - %s\n" "'bjobs'" "show summary of running jobs"
    printf "%-25s - %s\n" "'bhosts'" "show summary of available hosts"
fi
