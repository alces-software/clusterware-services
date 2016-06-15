################################################################################
##
## Alces Clusterware - Clusterware MOTD banner
## Copyright (c) 2016 Stephen F. Norledge and Alces Software Ltd
##
################################################################################
if [[ :"$LOADEDMODULES": == *":services/s3cmd:"* ]]; then
    echo ""
    printf "%-25s - %s\n" "'s3cmd --help'" "show help for S3cmd"
    printf "%-25s - %s\n" "'s3cmd ls [<bucket>]'" "list objects or buckets"
    printf "%-25s - %s\n" "'s3cmd put <file> <s3>'" "put file into bucket"
    printf "%-25s - %s\n" "'s3cmd get <s3> <file>'" "get file from bucket"
fi
