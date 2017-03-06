#!/bin/bash

require ruby

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
  repo_type=$(customize_repository_type "$repo_url")

  require "customize-repository-${repo_type}"

  customize_repository_${repo_type}_index "$repo_url"
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

  manifest = YAML.load_file("${manifest_file}")

  manifest["profiles"].each do | profile_name, profile |
    puts "${repo_name}/#{bold(profile_name)}"
  end
RUBY
}
