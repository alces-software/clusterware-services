#==============================================================================
# Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
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

_assert_profile_included() {
  if [[ -z $1 ]]; then
    action_die "A profile is required"
  fi
}

customize_slave_add() { 
  local profile
  profile=$1
  shift
  _assert_profile_included $profile

  ruby_run <<RUBY
require 'yaml'
begin
  data = YAML.load_file("$_CUSTOMIZE_SLAVE_CONFIG")
  exit 2 if data["profiles"].include? "$profile"
  data["profiles"].push("$profile")
  File.open("$_CUSTOMIZE_SLAVE_CONFIG", "w").write(data.to_yaml)
rescue Errno::ENOENT
  exit 1
rescue NoMethodError
  exit 3
rescue
  exit -1
end
RUBY

  case "$?" in
    0)
      action_exit 0;;
    1)
      action_die "Failed to load: $_CUSTOMIZE_SLAVE_CONFIG";;
    2)
      action_die "Profile already added";;
    3)
      action_die "Error updating config, check format: $_CUSTOMIZE_SLAVE_CONFIG";;
    *)
      action_die "An unknown error has occurred"
  esac
}

customize_slave_remove() { 
  local profile
  profile=$1
  shift
  _assert_profile_included $profile

  ruby_run <<RUBY
require 'yaml'
begin
  data = YAML.load_file("$_CUSTOMIZE_SLAVE_CONFIG")
  exit 2 unless data["profiles"].include? "$profile"
  data["profiles"].delete("$profile")
  File.open("$_CUSTOMIZE_SLAVE_CONFIG", "w").write(data.to_yaml)
rescue Errno::ENOENT
  exit 1
rescue NoMethodError
  exit 3
rescue
  exit -1
end
RUBY

  case "$?" in
    0)
      action_exit 0;;
    1)
      action_die "Failed to load: $_CUSTOMIZE_SLAVE_CONFIG";;
    2)
      action_die "$profile not found in profiles list";;
    3)
      action_die "Error updating config, check format: $_CUSTOMIZE_SLAVE_CONFIG";;
    *)
      action_die "An unknown error has occurred"
  esac
}

customize_slave_list() { 
  ruby_run <<RUBY
require 'yaml'
begin
  data = YAML.load_file("$_CUSTOMIZE_SLAVE_CONFIG")
  exit 2 if data["profiles"].empty?
  puts data["profiles"]
rescue Errno::ENOENT
  exit 1
rescue NoMethodError
  exit 3
rescue
  exit -1
end
RUBY
  
  case "$?" in
    0)
      action_exit 0;;
    1)
      action_die "Failed to load: $_CUSTOMIZE_SLAVE_CONFIG";;
    2)
      action_die "No profiles listed";;
    3)
      action_die "Error reading config, check format: $_CUSTOMIZE_SLAVE_CONFIG";;
    *)
      action_die "An unknown error has occurred"
  esac
}