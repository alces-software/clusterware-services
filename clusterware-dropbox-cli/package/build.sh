#!/bin/bash

package_name='clusterware-dropbox-cli'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

mkdir -p "${temp_dir}/data/opt"
pushd "${temp_dir}/data/opt" > /dev/null

curl -L "https://github.com/alces-software/clusterware-dropbox-cli/archive/master.zip" -o /tmp/dropbox-cli.zip

unzip /tmp/dropbox-cli.zip
mv clusterware-dropbox-cli-master clusterware-dropbox-cli
cd clusterware-dropbox-cli
/opt/clusterware/opt/ruby/bin/bundle install --without="development test" --path=vendor

cat <<EOF > .env
#==============================================================================
# Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware Dropbox.
#
# Alces Clusterware Dropbox is free software: you can redistribute it
# and/or modify it under the terms of the GNU Affero General Public
# License as published by the Free Software Foundation, either version
# 3 of the License, or (at your option) any later version.
#
# Alces Clusterware Dropbox is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware Dropbox, please visit:
# https://github.com/alces-software/clusterware-dropbox
#==============================================================================
cw_STORAGE_dropbox_appkey='rfi1onbc9xemltz'
cw_STORAGE_dropbox_appsecret='5xctss4cpfnqli8'
EOF

rm -f /tmp/dropbox-cli.zip

popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
