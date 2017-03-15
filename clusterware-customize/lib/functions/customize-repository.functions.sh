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
  # Additional repository types can be added here with a supporting functions
  # file `customize-repository-<type>.functions.sh`, providing the following
  # functions:
  #
  # - customize_repository_<type>_index "$repo_url"
  #    - prints repo index YAML to stdout
  # - customize_repository_<type>_install "$repo_name" "$repo_url" "$profile_name" "$target"
  #    - copies a profile from a repo to a target directory
  # - customize_repository_<type>_push "$repo_url" "$src_directory"
  #    - copies a profile from a directory to a repo
  # - customize_repository_<type>_set_index "$repo_url" "$index_file"
  #    - copies an index YAML file to a repo
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

  if [[ "$tags" == *"startup"* ]]; then
    return 1
  fi
  return 0
}

customize_repository_apply() {
  local is_preinit repo_name profile_name target
  repo_name="$1"
  profile_name="$2"
  is_preinit="$3"

  if _is_installable "$repo_name" "$profile_name" || [[ "$is_preinit" == "preinit" ]]; then
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


customize_repository_push() {
  local index profile_name repo_type repo_url retval src tmpdir
  src="$1"
  repo_name="${2:-account}"  # By default use account bucket
  repo_url=$(customize_repository_get_url "$repo_name")
  if [[ ! "$repo_url" ]]; then
    echo "Unknown repository: ${repo_name}"
    return 1
  fi
  repo_type=$(customize_repository_type "$repo_url")

  require "customize-repository-${repo_type}"

  profile_name=$(basename "$src")
  profile_name=${profile_name%.*}

  if [[ -f "$src" ]]; then
    tmpdir="/tmp/${profile_name}"

    mkdir -p "${tmpdir}/configure.d"
    cp "$src" "${tmpdir}/configure.d"
    src="$tmpdir"
  fi

  if [[ -d "$src" ]]; then
    # Generate (or re-generate) manifest.txt
    pushd "$src" > /dev/null
    find -H */* -type f -print > manifest.txt 2>/dev/null
    if [ $? -gt 0 ]; then
      echo "No subdirectory hooks found: this is not a valid profile directory"
      return 5
    fi
    popd > /dev/null

    echo "Pushing $profile_name to repository $repo_name..."

    customize_repository_${repo_type}_push "$repo_url" "$src"
    retval=$?

    if [ $retval -eq 0 ]; then
      echo "Push complete."
      echo "Updating repository index..."
      index=$(mktemp "/tmp/cluster-customizer.repo.XXXXXXXX")
      customize_repository_${repo_type}_index "$repo_url" > "$index" 2> /dev/null

      customize_repository_add_to_index "$index" "$src" "$profile_name"

      customize_repository_${repo_type}_set_index "$repo_url" "$index"
      if [ $? -eq 0 ]; then
        echo "Repository index updated."
      else
        echo "Failed to update repository index."
      fi

      rm -f "$index"
      if [[ "$tmpdir" ]]; then rm -rf "$tmpdir"; fi
    else
      echo "Push failed."
      if [[ "$tmpdir" ]]; then rm -rf "$tmpdir"; fi
      return 4
    fi
  else
    echo "Unknown type: $src"
    return 3
  fi

}

customize_repository_add_to_index() {
  local index_file profile_dir profile_name
  index_file="$1"
  profile_dir="$2"
  profile_name="$3"

  ruby_run <<RUBY
require 'yaml'

profile_dir = '$profile_dir'
profile_name = '$profile_name'
default_index = {'profiles' => {}}

begin
  index = YAML.load_file('$index_file') || default_index
rescue
  index = default_index
end

manifest_file = File.expand_path("manifest.txt", profile_dir)
tags_file = File.expand_path("tags.txt", profile_dir)

if File.exists?(manifest_file)
profile = {}

manifest = File.read(manifest_file).split("\n")
profile['manifest'] = manifest

if File.exists?(tags_file)
tags = File.read(tags_file).split("\n")
profile['tags'] = tags
end

if Dir.exists?("#{profile_dir}/initialize.d") || Dir.exists?("#{profile_dir}/preconfigure.d")
# Automagically tag profile as startup
if !profile.key?('tags')
  profile['tags'] = []
  File.write(tags_file, "startup\n")
end
if !profile['tags'].include?('startup')
  # tags were specified but startup was not. We should fix that:
  File.open(tags_file, 'a') { |f| f.write("startup\n") }
  profile['tags'] << 'startup'
end
end

index['profiles'][profile_name] = profile

File.open('$index_file', 'w') { |outFile|
outFile.write index.to_yaml
}
end
RUBY
}
