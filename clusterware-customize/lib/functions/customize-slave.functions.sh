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
require action
require ruby

_CUSTOMIZE_SLAVE_CONFIG="$cw_ROOT/etc/cluster-customizer/config.yml"

_customize_slave_assert_cli_include_profile() {
  local profile
  profile="$1"
  shift

  if [[ -z $profile ]]; then
    action_die "A profile is required"
  elif ! [[ $profile =~ ^.+/.+$ ]]; then
    action_die "A repository is required, <repo/profile>"
  elif [[ $(tr -dc "/" <<< $profile | awk '{print length}' ) -ne 1 ]]; then
    action_die "Unrecognized format: $profile"
  fi
}

_customize_slave_get_yaml_data() {
  ruby_run <<RUBY 2>/dev/null
require 'yaml'
begin
  data = YAML.load_file("$_CUSTOMIZE_SLAVE_CONFIG")
  if data.key? "profiles"
    data_profile = data["profiles"]
  else
    data_profile = []
  end
  puts data_profile
  exit 0
rescue
  exit 1
end
RUBY
  if [[ $? -ne 0 ]]; then
    action_die "Could not open config, check $_CUSTOMIZE_SLAVE_CONFIG"
  fi
}

_customize_slave_data_include_profile() {
  local data profile exit_code
  profile=$1
  shift
  data=$@

  ruby_run <<RUBY 2>/dev/null
begin
  data = "$data".split(" ")
  exit 0 if data.include? "$profile"
  exit 1
rescue
  exit 2
end
RUBY

  exit_code=$?
  if [[ $exit_code -eq 2 ]]; then
    action_die "Error in config format, check $_CUSTOMIZE_SLAVE_CONFIG"
  else
    return $exit_code
  fi
}

_customize_slave_update_profile() {
  local new_profile_data
  new_profile_data=$@

  ruby_run <<RUBY
require 'yaml'
begin
  data = YAML.load_file("$_CUSTOMIZE_SLAVE_CONFIG")
  data["profiles"] = "$new_profile_data".split(" ")
  File.write("$_CUSTOMIZE_SLAVE_CONFIG", data.to_yaml)
  exit 0
rescue
  exit 2
end
RUBY

  if [[ $? -eq 0 ]]; then
    action_exit 0
  else
    action_die "An error occured adding the profile"
  fi
}

customize_slave_add() {
  local profile
  profile=$1
  shift
  _customize_slave_assert_cli_include_profile $profile
  data=$(_customize_slave_get_yaml_data)
  if ( _customize_slave_data_include_profile $profile $data ); then
    action_die "Profile already added"
  fi
  _customize_slave_update_profile $profile $data
}

customize_slave_remove() {
  local profile
  profile=$1
  shift
  _customize_slave_assert_cli_include_profile $profile
  data=$(_customize_slave_get_yaml_data)
  if !( _customize_slave_data_include_profile $profile $data ); then
    action_die "$profile not found"
  fi
  new_profiles=""
  for i in $data; do
    if [[ "$i" != "$profile" ]]; then
      new_profiles="$new_profiles $i"
    fi
  done
  _customize_slave_update_profile $new_profiles
}

customize_slave_list() {
  _customize_slave_get_yaml_data
}

customize_slave_help() {
  cat <<EOF
SYNOPSIS:

  alces customize slave add <repo>/<profile>
  alces customize slave remove <repo>/<profile>
  alces customize slave list

DESCRIPTION:
  Manage customization profiles to be executed by slave nodes on boot.

  add:
    Add a customization profile to the centrally managed list.
  remove:
    Remove a customization profile from the centrally managed list.
  list:
    List customization profiles to be run

Please report bugs to support@alces-software.com
Alces Software home page: <http://alces-software.com>
EOF
}
