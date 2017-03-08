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

_can_access_s3_url() {
  local url
  url="$1"
  $S3CMD ls "${url}" 2>/dev/null
}

customize_repository_s3_index() {
  local retval url
  url="$1"
  _set_s3_config

  if _can_access_s3_url "$repo_url"; then
    $S3CMD get "$url/index.yml" -
    retval=$?
  else
    require customize-repository-http
    >&2 echo "Falling back to HTTP indexing as S3 access unavailable."

    if [ "${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}" == "us-east-1" ]; then
        host=s3.amazonaws.com
    else
        host=s3-${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}.amazonaws.com
    fi

    customize_repository_http_index "https://${host}/${repo_url##s3://}"
    retval="$?"
  fi

  _clear_s3_config
  return $retval
}

customize_repository_s3_install() {
  local host profile_name repo_name retval repo_url target
  repo_name="$1"
  repo_url="$2"
  profile_name="$3"
  target="$4"

  _set_s3_config

  if _can_access_s3_url "$repo_url"; then
    $S3CMD get --force -r "${repo_url}/${profile_name}/" "${target}"
    retval="$?"
  else
    require customize-repository-http
    >&2 echo "Falling back to HTTP installation as S3 access unavailable."

    if [ "${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}" == "us-east-1" ]; then
        host=s3.amazonaws.com
    else
        host=s3-${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}.amazonaws.com
    fi

    customize_repository_http_install "$repo_name" "https://${host}/${repo_url##s3://}" "$profile_name" "$target"
    retval="$?"
  fi
  _clear_s3_config
  return $retval
}
