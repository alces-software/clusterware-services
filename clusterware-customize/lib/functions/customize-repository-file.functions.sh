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

customize_repository_file_index() {
  local url
  url="$1"
  cat "${url}/index.yml"
  return $?
}

customize_repository_file_install() {
  local repo_name repo_url profile_name target
  repo_name="$1"
  repo_url="$2"
  profile_name="$3"
  target="$4"

  cp -r "${repo_url}/${profile_name}" "${target}"
}

customize_repository_file_push() {
  local dest src
  dest="$1"
  src="$2"

  cp -r "$src" "$dest"
}

customize_repository_file_set_index() {
  local repo_url src
  repo_url="$1"
  src="$2"

  cp "$src" "$repo_url"/index.yml
}
