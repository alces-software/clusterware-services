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
require 'digest/sha1'

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def bold(text)
  colorize(text, 1)
end

MAX_COLOUR_CODE = 230

def colour_for_tag(tag)
  colour_code = (Digest::SHA1.hexdigest(tag).to_i(16) % MAX_COLOUR_CODE) + 1
  if colour_code == 16
    colour_code = "16;48;5;15"  # Black on white background
  end
  "38;5;#{colour_code}"
end

def tags_to_string(tags)
  return "" if not tags
  tag_strings = []
  tags.sort.each { |tag|
    tag_strings << colorize(tag, colour_for_tag(tag))
  }
  tag_strings.join(' ')
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
    profiles = manifest["profiles"].select {|prn, pr| should_list?(prn, pr) }.sort
    max_len = profiles.map { |pf, pp| pf.length }.max + 10
    profiles.each do | profile_name, profile |
      puts "${repo_name}/#{bold(profile_name).ljust(max_len)}#{tags_to_string(profile['tags'])}"
    end
  end
RUBY
}

customize_repository_tags_for() {
  local profile_name repo_name tmpfile
  repo_name="$1"
  profile_name="$2"
  tmpfile=$(mktemp "/tmp/cluster-customizer.repo.XXXXXXXX")

  customize_repository_index "$repo_name" > "$tmpfile"

  ruby_run <<RUBY
require 'yaml';

idx = YAML.load_file("${tmpfile}")

if idx.is_a?(Hash) && idx.key?('profiles')
  if idx['profiles'].key?('${profile_name}')
    if idx['profiles']['${profile_name}'].key?('tags')
      puts idx['profiles']['${profile_name}']['tags'].join(' ')
    end
  end
end

RUBY

  rm -r "$tmpfile"
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

_is_installable() {
  local profile_name repo_name tags
  repo_name="$1"
  profile_name="$2"
  tags=$(customize_repository_tags_for "$repo_name" "$profile_name")

  if [[ "$tags" == *"pre-init"* ]]; then
    return 1
  fi
  return 0
}

customize_repository_apply() {
  local repo_name profile_name target
  repo_name="$1"
  profile_name="$2"

  if _is_installable "$repo_name" "$profile_name"; then
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
  else
    echo "The profile ${repo_name}/${profile_name} is not installable as it needs to be configured at boot-time."
  fi

}
