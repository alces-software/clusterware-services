################################################################################
##
## Alces Clusterware - Clusterware MOTD banner script
## Copyright (c) 2016 Stephen F. Norledge and Alces Software Ltd
##
################################################################################
if [[ :"$LOADEDMODULES": == *":services/slurm:"* ]]; then
    echo ""
    printf "%-25s - %s\n" "'sbatch'" "submit a batch job"
    printf "%-25s - %s\n" "'squeue'" "view information about jobs"
    printf "%-25s - %s\n" "'sinfo'" "view information about nodes and partitions"
fi
