#!/bin/bash

require ruby
require member

_DEFAULT_CONF_FILE="${cw_ROOT}/etc/cluster-customizer/config.yml"

customize_repository_get_url() {
  local conffile name
  name="$1"
  conffile="${2:-$_DEFAULT_CONF_FILE}"

  ruby_run <<RUBY
require 'yaml'
repo_list = YAML.load_file("${conffile}")["repositories"]

if repo_list.key? "${name}"
  puts repo_list["${name}"]
end
RUBY
}

customize_repository_type() {
  local url
  url="$1"
  if [[ "$url" == "http:/"* || "$url" == "https:/"* ]]; then
    echo "http"
  elif [[ "$url" == "s3:/"* ]]; then
    echo "s3"
  elif [[ "$url" == "/"* ]]; then
    echo "file"
  fi
}

customize_repository_index() {
  local repo_name repo_url repo_type
  repo_name="$1"
  repo_url=$(customize_repository_get_url "$repo_name")
  if [[ ! "$repo_url" ]]; then
    echo "Unknown repository: ${repo_name}"
    return 1
  fi
  repo_type=$(customize_repository_type "$repo_url")

  require "customize-repository-${repo_type}"

  customize_repository_${repo_type}_index "$repo_url"
  return $?
}

customize_repository_list_profiles() {
  local manifest_file repo_name
  repo_name="$1"
  manifest_file="$2"
  ruby_run <<RUBY
require 'yaml'

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def bold(text)
  colorize(text, 1)
end

def installed?(profile_name)
  File.exists?("${cw_CLUSTER_CUSTOMIZER_path}/${repo_name}-#{profile_name}")
end

def hidden?(profile)
  profile.key?("tags") && profile["tags"].include?("hidden")
end

def should_list?(profile_name, profile)
  !installed?(profile_name) && !hidden?(profile)
end

  manifest = YAML.load_file("${manifest_file}") || {}

  if manifest.is_a?(Hash) && manifest.key?("profiles")
    manifest["profiles"].select {|prn, pr| should_list?(prn, pr) }.each do | profile_name, profile |
      puts "${repo_name}/#{bold(profile_name)}"
    end
  end
RUBY
}

_list_repo_names() {
  ruby_run <<RUBY
require 'yaml'
repo_list = YAML.load_file("${_DEFAULT_CONF_FILE}")["repositories"]

repo_list.keys.each do |name|
  puts name
end
RUBY
}

customize_repository_each() {
  local callback r repos
  callback="$1"
  repos=$(_list_repo_names)
  for r in $repos; do
    $callback "$r"
  done
}

_run_member_hooks() {
    local event name ip
    members="$1"
    event="$2"
    shift 3
    name="$1"
    ip="$2"
    if [[ -z "${members}" || ,"$members", == *,"${name}",* ]]; then
       customize_run_hooks "${event}" \
                           "${cw_MEMBER_DIR}"/"${name}" \
                           "${name}" \
                           "${ip}"
    fi
}

customize_repository_apply() {
  local repo_name profile_name target
  repo_name="$1"
  profile_name="$2"

  repo_url=$(customize_repository_get_url "$repo_name")
  if [[ ! "$repo_url" ]]; then
    echo "Unknown repository: ${repo_name}"
    return 1
  fi
  repo_type=$(customize_repository_type "$repo_url")

  require "customize-repository-${repo_type}"

  target="${cw_CLUSTER_CUSTOMIZER_path}/${repo_name}-${profile_name}"
  mkdir -p "$target"

  customize_repository_${repo_type}_install "$repo_name" "$repo_url" "$profile_name" "$target"

  if [[ $? -eq 0 ]]; then
    if rmdir "${target}" 2>/dev/null; then
      # If rmdir succeeds then the directory was empty => install failed
      echo "No profile found for: ${repo_name}/${profile_name}"
      return 1
    fi
    chmod -R a+x "${cw_CLUSTER_CUSTOMIZER_path}/${repo_name}-${profile_name}"
    echo "Running configure for $profile_name"
    customize_run_hooks "configure:$repo_name-$profile_name"
    member_each _run_member_hooks "${members}" "member-join:$repo_name-$profile_name"
    return 0
  fi

}
