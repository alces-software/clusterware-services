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

customize_repository_http_index() {
  local url
  url="$1"
  curl -s -f "${url}/index.yml"
  return $?
}

customize_repository_http_install() {
  local manifest profile_name repo_name repo_url target
  repo_name="$1"
  repo_url="$2"
  profile_name="$3"
  target="$4"

  manifest=$(curl -s -f "${repo_url}/${profile_name}/manifest.txt")

  if [ "${manifest}" ] && ! echo "${manifest[*]}" | grep -q '<Error>'; then
      # fetch each file within manifest file
      for f in ${manifest}; do
          mkdir -p "${target}/$(dirname "$f")"
          if curl -s -f -o ${target}/${f} "${repo_url}/${profile_name}/${f}"; then
              echo "Fetched: ${f}"
          else
              echo "Unable to fetch: ${f}"
              return 1
          fi
      done
  else
      echo "No manifest found for ${repo_name}/${profile_name}"
      return 1
  fi
}
