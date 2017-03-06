#!/bin/bash
#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# Alces Clusterware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Clusterware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware, please visit:
# https://github.com/alces-software/clusterware
#==============================================================================

require files
require network

_set_region() {
    if [ -z "${_REGION}" ]; then
        if network_is_ec2; then
            eval $(network_fetch_ec2_document | "${cw_ROOT}"/opt/jq/bin/jq -r '"_REGION=\(.region)"')
        else
            _REGION="${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}"
        fi
    fi
}

_set_s3_config() {
  _set_region
  s3cfg="$(mktemp /tmp/cluster-customizer.s3cfg.XXXXXXXX)"
  cat <<EOF > "${s3cfg}"
[default]
access_key = "${cw_CLUSTER_CUSTOMIZER_access_key_id}"
secret_key = "${cw_CLUSTER_CUSTOMIZER_secret_access_key}"
security_token = ""
use_https = True
check_ssl_certificate = True
EOF
  S3CMD="${cw_ROOT}/opt/s3cmd/s3cmd -c ${s3cfg} -q"
}

_clear_s3_config() {
  rm -f "${s3cfg}"
  unset s3cfg
  unset S3CMD
}

customize_repository_s3_index() {
  local url
  url="$1"
  _set_s3_config

  $S3CMD get "$url/index.yml" -

  _clear_s3_config
}
