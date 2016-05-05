################################################################################
##
## Alces Clusterware - Clusterware MOTD banner script
## Copyright (c) 2016 Stephen F. Norledge and Alces Software Ltd
##
################################################################################
if [[ :"$LOADEDMODULES": == *":services/gridscheduler:"* ]]; then
    echo ""
    printf "%-25s - %s\n" "'qstat'" "show summary of running jobs"
    printf "%-25s - %s\n" "'qsub'" "submit a job script"
    printf "%-25s - %s\n" "'qdesktop'" "submit an interactive session request"
fi
