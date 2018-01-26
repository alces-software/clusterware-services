#!/bin/bash

curl "https://s3.amazonaws.com/aws-cli/awscli-bundle-1.10.19.zip" -o "/tmp/awscli-bundle.zip"
pushd /tmp > /dev/null
unzip awscli-bundle.zip
./awscli-bundle/install -i "${cw_ROOT}"/opt/aws
popd > /dev/null

rm -rf /tmp/awscli-bundle*

# install environment module
mkdir -p "${cw_ROOT}"/etc/modules/services
sed -e "s,_cw_ROOT_,${cw_ROOT},g" data/aws-module.template > "${cw_ROOT}"/etc/modules/services/aws
sed -e 's,^module load \(.*\),module load services/aws \1,g' -i "${cw_ROOT}"/etc/skel/modules

mkdir -p "${cw_ROOT}"/etc/motd.d
cp data/motd.sh "${cw_ROOT}"/etc/motd.d/00-tips-20-aws.sh
