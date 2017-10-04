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
require ruby
require distro
_COMPUTE_JO=${cw_ROOT}/opt/jo/bin/jo
_COMPUTE_JQ=${cw_ROOT}/opt/jq/bin/jq

_compute_load_personality() {
  if [ -z "${_COMPUTE_PERSONALITY_LOADED}" ]; then
    eval $(_compute_extract_personality)
    _COMPUTE_PERSONALITY_LOADED=true
  fi
}

_compute_extract_personality() {
  ruby_run <<RUBY
require 'yaml'
p_file = '${cw_ROOT}/etc/personality.yml'
begin
  if File.exists?(p_file)
    personality = YAML.load_file(p_file)
    if compute_config = personality['compute']
      if compute_config.key?('cluster')
        puts "_COMPUTE_cluster_name=#{compute_config['cluster']}"
      end
      if compute_config.key?('auth_user')
        puts "_COMPUTE_auth_user=#{compute_config['auth_user']}"
      end
    end
  end
end
RUBY
}

_compute_auth() {
  _compute_load_personality
  if [ -z "${cw_CLUSTER_auth_token}" ]; then
      files_load_config auth config/cluster
  fi
  if [ -z "${cw_NETWORK_domain}" ]; then
      files_load_config network
  fi
  user=${_COMPUTE_auth_user:-$(echo "${cw_NETWORK_domain}" | cut -f1-2 -d'.')}
  echo "${user}:${cw_CLUSTER_auth_token}"
}

_compute_cluster() {
  _compute_load_personality
  if [ -z "${_COMPUTE_cluster_name}" ]; then
    if [ -z "${cw_CLUSTER_name}" ]; then
        files_load_config config config/cluster
    fi
    echo "${cw_CLUSTER_name}"
  else
    echo "${_COMPUTE_cluster_name}"
  fi
}

_compute_endpoint() {
  local cluster queue
  queue="$1"
  cluster="$(_compute_cluster)"
  if [ "${queue}" ]; then
      echo "${_COMPUTE_ENDPOINT_URL:-https://tracon.alces-flight.com}/clusters/${cluster}/queues/${queue}"
  else
      echo "${_COMPUTE_ENDPOINT_URL:-https://tracon.alces-flight.com}/clusters/${cluster}/queues"
  fi
}

_compute_endpoint_available() {
    local endpoint
    endpoint="$1"
    webapi_send HEAD "${_COMPUTE_ENDPOINT_URL:-https://tracon.alces-flight.com}/ping" --skip-payload
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
      mkdir -p "${cw_ROOT}/etc/config/autoscaling/by-label"

      # log "New compute group: ${compute_group_label} => ${compute_group}"
      ln -s "${cw_ROOT}/etc/config/autoscaling/groups/${group}" "${cw_ROOT}/etc/config/autoscaling/by-label/${queue}"

      # This is the first time we've seen this group
      mkdir -p "${cw_ROOT}/etc/config/autoscaling/groups/${group}"

      if [ ! -e "${cw_ROOT}/etc/config/autoscaling/default" ]; then
          ln -s "${cw_ROOT}/etc/config/autoscaling/by-label/${queue}" "${cw_ROOT}/etc/config/autoscaling/default"
      fi

      #log "Triggering local 'autoscaling-add-group' event with: ${queue} ${max} ${cores} ${ram_mib}"
      "${cw_ROOT}"/libexec/share/trigger-event --local autoscaling-add-group "${queue}" "${max}" "${cores}" "${ram_mib}"
      _COMPUTE_CORES="${cores}"
  else
    return 1
  fi
}

_compute_loadq() {
  local queue group_size group_min group_max group_cores
  queue="$1"
  if [ -z "$_COMPUTE_QUEUE_LOADED" ]; then
      if files_load_config --optional group config/autoscaling/by-label/${queue}; then
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
  local queue nodefiles upcount
  queue="$1"
  # delete queue data file, allowing the queue to be scaled down
  _compute_loadq "$queue"
  if [ "$_COMPUTE_QUEUE_LOADED" ]; then
      shopt -s nullglob
      nodefiles=("${cw_ROOT}"/etc/config/autoscaling/by-label/${queue}/*)
      upcount=$((${#nodefiles[@]}-1))
      shopt -u nullglob
      rm -f "${cw_ROOT}"/etc/config/autoscaling/by-label/${queue}/group.rc
      # remove from scheduler forcibly if no nodes are currently up
      # (if nodes are up, this will happen automatically when the
      # final node member leaves.)
      if [ "${upcount}" == "0" ]; then
	  "${cw_ROOT}"/libexec/share/trigger-event --local autoscaling-prune-group "${queue}"
      fi
  fi
}

_compute_updateq() {
  local queue size min max group new_queue
  queue="$1"
  size="$2"
  min="$3"
  max="$4"
  group="$5"
  # update queue data file
  if [ -z "$_COMPUTE_QUEUE_LOADED" ]; then
      if ! _compute_loadq "${queue}"; then
          # unable to load; this is a new queue
	  new_queue=true
          if ! _compute_setupq "${queue}" "${group}" "${max}"; then
              # unable to set up queue! ouch!
              return 1
          fi
      fi
  fi
  if [ "$new_queue" != "true" ]; then
      # fire an event to cause the scheduler config to be updated with the new max
      "${cw_ROOT}"/libexec/share/trigger-event --local autoscaling-update-group "${queue}" "${_COMPUTE_MAX}" "${max}" "${_COMPUTE_CORES}" "$(_compute_ram_for_queue "${queue}")"
  fi
  cat <<EOF > "${cw_ROOT}"/etc/config/autoscaling/by-label/${queue}/group.rc
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
  local method queue size min max auth endpoint result code
  method="$1"
  queue="$2"
  size="$3"
  min="$4"
  max="$5"
  endpoint="$(_compute_endpoint "${queue}")"
  auth="$(_compute_auth)"

  if ! _compute_endpoint_available; then
      [ "${_COMPUTE_ACCEPTED_HOOK}" ] && $_COMPUTE_ACCEPTED_HOOK 1
      _COMPUTE_ERROR="unable to reach compute management service"
      return 1
  fi

  if [ "$method" == "DELETE" ]; then
      result=$(webapi_delete "${endpoint}" --emit-code --auth "${auth}" --mimetype "application/json")
      eval $(echo "$result" | grep '^code=')
      if [ "$code" == "204" ]; then
          _compute_removeq "${queue}"
      else
	  _COMPUTE_ERROR=$(echo "$result" | grep -v '^code=' | ${_COMPUTE_JQ} -r '.errors[0]')
	  return 1
      fi
  elif [ "$method" == "GET" ]; then
      webapi_send "${method}" "${endpoint}" --auth "${auth}" --mimetype "application/json" --skip-payload
  else
      result=$(_compute_payload "${size}" "${min}" "${max}" | \
          webapi_send "${method}" "${endpoint}" --emit-code --auth "${auth}" --mimetype "application/json")
      eval $(echo "$result" | grep '^code=')
      if [ "$code" == "202" ]; then
	  [ "${_COMPUTE_ACCEPTED_HOOK}" ] && $_COMPUTE_ACCEPTED_HOOK 0
          # we loop here, waiting for creation to complete.
	  # XXX - consider bellman?
          group=$(_compute_get_group "${queue}")
	  [ "${_COMPUTE_CREATED_HOOK}" ] && $_COMPUTE_CREATED_HOOK 0
          _compute_updateq "${queue}" "${size}" "${min}" "${max}" "${group}"
      else
	  [ "${_COMPUTE_ACCEPTED_HOOK}" ] && $_COMPUTE_ACCEPTED_HOOK 1
	  _COMPUTE_ERROR=$(echo "$result" | grep -v '^code=' | ${_COMPUTE_JQ} -r '.errors[0]')
	  return 1
      fi
  fi
}

_compute_get_group() {
  local queue endpoint auth result
  queue="$1"
  endpoint="$(_compute_endpoint "${queue}")"
  auth="$(_compute_auth)"
  while ! result=$(compute_call "GET" "${queue}"); do
      sleep 5
  done
  echo "$result" | ${_COMPUTE_JQ} -r .name
}

compute_shoot() {
  local queue node_id auth endpoint local
  queue="$1"
  node_id="$2"
  endpoint="$(_compute_endpoint "${queue}")"
  auth="$(_compute_auth)"
  result=$(webapi_delete "${endpoint}"/nodes/${node_id} --emit-code --auth "${auth}" --mimetype "application/json")
  eval $(echo "$result" | grep '^code=')
  if [ "$code" == "204" ]; then
      _compute_loadq "${queue}"
      group="$(compute_group_from_label)"
      _compute_updateq "${queue}" "$(($_COMPUTE_SIZE-1))" \
                           "${_COMPUTE_MIN}" "${_COMPUTE_MAX}" \
                           "${group}"
  else
      _COMPUTE_ERROR=$(echo "$result" | grep -v '^code=' | ${_COMPUTE_JQ} -r '.errors[0]')
      return 1
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

compute_list() {
    local result
    if result=$(compute_call GET); then
	ruby_run <<RUBY
require 'json'
queues = JSON.parse('${result}')
if queues.empty?
  puts "No queues."
  exit 0
end
queues.each do |queue|
  spec = queue['spec']
  nodes = []
  Dir.glob("${cw_ROOT}/etc/config/autoscaling/groups/#{queue['name']}/*").each do |f|
    f = File.basename(f)
    next if f == 'group.rc'
    nodes << f.split('.')[0]
  end
  puts "#{spec}"
  puts "#{'-' * spec.length}"
  printf("%12s: %s\n", 'Running', "#{nodes.length}/#{queue['current']}")
  printf("%12s: %s\n", 'Capacity', "#{queue['min']}-#{queue['max']}")
  printf("%12s: %s\n", 'Identifier', queue['name'])
  printf("%12s: %s\n", 'Nodes', nodes.join(', ')) unless nodes.empty?
  puts ""
end
RUBY
    else
	_COMPUTE_ERROR="unable to reach compute management service"
	return 1
    fi
}

compute_valid_queue() {
    local queue
    queue="$1"
    _compute_loadq "${queue}"
    [ -n "${_COMPUTE_QUEUE_LOADED}" ]
}
