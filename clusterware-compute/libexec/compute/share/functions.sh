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
require webapi
require files
_COMPUTE_JO=${cw_ROOT}/opt/jo/bin/jo
_COMPUTE_JQ=${cw_ROOT}/opt/jq/bin/jq

_compute_auth() {
  if [ -z "${cw_COMPUTE_auth}" ]; then
      files_load_config auth config/cluster
  fi
  echo "${cw_COMPUTE_auth}"
}

_compute_cluster() {
  if [ -z "${cw_CLUSTER_name}" ]; then
      files_load_config config config/cluster
  fi
  echo "${cw_CLUSTER_name}"
}

_compute_endpoint() {
  local cluster queue
  queue="$1"
  cluster="$(_compute_cluster)"
  echo "${_COMPUTE_ENDPOINT_URL:-https://tracon.alces-flight.com}/clusters/${cluster}/queues/${queue}"
}

_compute_payload() {
  local size min max
  size="$1"
  min="$2"
  max="$3"
  ${_COMPUTE_JO} desired=$size min=$min max=$max
}

_compute_value_for_queue() {
  local queue value
  queue="$1"
  value="$2"
  ruby_run <<RUBY
require 'yaml'
group_file = '${cw_ROOT}/etc/autoscaling/group.yml'
groups = if File.exist?(group_file)
  YAML.load_file(group_file)
else
  {
    'general-pilot' => {cores: 2, ram_mib: 3840 },
    'general-economy' => {cores: 36, ram_mib: 60 * 1024 },
    'general-durable' => {cores: 36, ram_mib: 60 * 1024 },
    'gpu-pilot' => {cores: 8, ram_mib: 15 * 1024 },
    'gpu-economy' => {cores: 32, ram_mib: 488 * 1024 },
    'gpu-durable' => {cores: 32, ram_mib: 488 * 1024 },
    'highmem-economy' => {cores: 32, ram_mib: 244 * 1024 },
    'highmem-durable' => {cores: 32, ram_mib: 244 * 1024 },
    'balanced-economy' => {cores: 40, ram_mib: 160 * 1024 },
    'balanced-durable' => {cores: 40, ram_mib: 160 * 1024 },
  }
end
if groups.key?('${queue}')
  if groups['${queue}'].key?(:${value})
    puts groups['${queue}'][:${value}]
  else
    exit 1
  end
end
RUBY
}

_compute_cores_for_queue() {
  local queue
  queue="$1"
  _compute_value_for_queue "${queue}" "cores"
}

_compute_ram_for_queue() {
  local queue
  queue="$1"
  _compute_value_for_queue "${queue}" "ram_mib"
}

_compute_setupq() {
  local queue group cores ram_mib max
  queue="$1"
  group="$2"
  max="$3"
  # determine group metadata for queue
  cores=$(_compute_cores_for_queue "${queue}")
  ram_mib=$(_compute_ram_for_queue "${queue}")

  if [ -n "${cores}" -a -n "${ram_mib}" ]; then
      mkdir -p "${cw_ROOT}/etc/config/compute/by-label"

      # log "New compute group: ${compute_group_label} => ${compute_group}"
      ln -s "${cw_ROOT}/etc/config/autoscaling/groups/${group}" "${cw_ROOT}/etc/config/autoscaling/by-label/${queue}"

      # This is the first time we've seen this group
      mkdir -p "${cw_ROOT}/etc/config/autoscaling/groups/${group}"

      if [ ! -e "${cw_ROOT}/etc/config/autoscaling/default" ]; then
          ln -s "${cw_ROOT}/etc/config/autoscaling/by-label/${queue}" "${cw_ROOT}/etc/config/autoscaling/default"
      fi

      #log "Triggering local 'autoscaling-add-group' event with: ${queue} ${max} ${cores} ${ram_mib}"
      "${cw_ROOT}"/libexec/share/trigger-event --local autoscaling-add-group "${queue}" "${max}" "${cores}" "${ram_mib}"
  else
    return 1
  fi
}

_compute_loadq() {
  local queue group_size group_min group_max group_cores
  queue="$1"
  if [ -z "$_COMPUTE_QUEUE_LOADED" ]; then
      if files_load_config --optional group config/autoscaling/groups/by-label/${queue}; then
          _COMPUTE_SIZE=${group_size}
          _COMPUTE_MIN=${group_min}
          _COMPUTE_MAX=${group_max}
          _COMPUTE_CORES=${group_cores}
          _COMPUTE_QUEUE_LOADED=true
      else
        return 1
      fi
  fi
}

_compute_removeq() {
  local queue
  queue="$1"
  # delete queue data file, allowing the queue to be scaled down
  rm -f "${cw_ROOT}"/etc/config/autoscaling/groups/by-label/${queue}/group.rc
}

_compute_updateq() {
  local queue size min max group
  queue="$1"
  size="$2"
  min="$3"
  max="$4"
  group="$5"
  # update queue data file
  if [ -z "$_COMPUTE_QUEUE_LOADED" ]; then
      if ! _compute_loadq "${queue}"; then
          # unable to load; this is a new queue
          if ! _compute_setupq "${queue}" "${group}" "${max}"; then
              # unable to set up queue! ouch!
              return 1
          fi
      fi
  fi
  # XXX - should update scheduler config with new max somehow...
  cat <<EOF > "${cw_ROOT}"/etc/config/autoscaling/groups/by-label/${queue}/group.rc
group_size=${size}
group_min=${min}
group_max=${max}
group_cores=${_COMPUTE_CORES}
EOF
}

compute_group_from_label() {
  local label
  label="$1"
  if [ -e "${cw_ROOT}/etc/config/autoscaling/by-label/${label}" ]; then
    basename `readlink "${cw_ROOT}/etc/config/autoscaling/by-label/${label}"`
  fi
}

compute_call() {
  local method queue size min max auth endpoint result
  method="$1"
  queue="$2"
  size="$3"
  min="$4"
  max="$5"
  endpoint="$(_compute_endpoint "${queue}")"
  auth="$(_compute_auth)"

  if [ "$method" == "DELETE" ]; then
      if webapi_delete "${endpoint}" --auth "${auth}" --mimetype "application/json"; then
          _compute_removeq "${queue}"
      fi
  else
    if _compute_payload "${size}" "${min}" "${max}" | \
          webapi_send "${method}" "${endpoint}" --auth "${auth}" --mimetype "application/json"; then
        # we don't know what the group ID is by this point. dammit.
        # maybe we loop here, waiting for creation to complete?
        group=$(_compute_get_group "${queue}")
        _compute_updateq "${queue}" "${size}" "${min}" "${max}" "${group}"
    fi
  fi
}

_compute_get_group() {
  local queue endpoint auth result
  queue="$1"
  endpoint="$(_compute_endpoint "${queue}")"
  auth="$(_compute_auth)"
  while ! result=$(webapi_send "GET" "${endpoint}" --auth "${auth}" --mimetype "application/json"); do
      sleep 5
  done
  echo "$result" | ${_COMPUTE_JQ} .name
}

compute_shoot() {
  local queue node_id auth endpoint local
  queue="$1"
  node_id="$2"
  endpoint="$(_compute_endpoint "${queue}")"
  auth="$(_compute_auth)"
  if webapi_delete "${endpoint}"/nodes/${node_id} --auth "${auth}" --mimetype "application/json"; then
      _compute_loadq "${queue}"
      group="$(compute_group_from_label)"
      _compute_updateq "${queue}" "$(($_COMPUTE_SIZE-1))" \
                           "${_COMPUTE_MIN}" "${_COMPUTE_MAX}" \
                           "${group}"
  fi
}

compute_size() {
  local queue
  queue="$1"
  _compute_loadq "${queue}"
  echo "${_COMPUTE_SIZE}"
}

compute_min() {
  local queue
  queue="$1"
  _compute_loadq "${queue}"
  echo "${_COMPUTE_MIN}"
}

compute_max() {
  local queue
  queue="$1"
  _compute_loadq "${queue}"
  echo "${_COMPUTE_MAX}"
}
