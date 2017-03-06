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
require files

customize_list_hooks() {
    local p paths with_events e
    if [ "$1" == "--with-events" ]; then
        with_events=true
        shift
    fi
    files_load_config cluster-customizer
    cw_CLUSTER_CUSTOMIZER_path=${cw_CLUSTER_CUSTOMIZER_path:-"${cw_ROOT}"/var/lib/customizer}
    paths="${cw_CLUSTER_CUSTOMIZER_custom_paths}"
    for p in ${cw_CLUSTER_CUSTOMIZER_path}/*; do
        paths="${paths} ${p}"
    done
    for p in ${paths}; do
        if [ "${with_events}" ]; then
            for e in "${p}"/*; do
                echo -e "\e[38;5;221m$(basename "${p}")\e[0m/\e[35m$(basename "${e}" .d)\e[0m"
            done
        else
            basename "${p}"
        fi
    done
}

customize_run_hooks() {
    local a p hook paths feature
    hook="$1"
    if [[ "$hook" == *":"* ]]; then
        feature="${hook#*:}"
        hook="${hook%:*}"
    fi
    shift
    files_load_config config config/cluster
    files_load_config instance config/cluster
    files_load_config cluster-customizer
    cw_CLUSTER_CUSTOMIZER_path=${cw_CLUSTER_CUSTOMIZER_path:-"${cw_ROOT}"/var/lib/customizer}
    paths="${cw_CLUSTER_CUSTOMIZER_custom_paths}"
    for p in ${cw_CLUSTER_CUSTOMIZER_path}/*; do
        paths="${paths} ${p}"
    done
    for p in ${paths}; do
        if [[ -z "${feature}" || "${p}" == */"${feature}" ]]; then
            if [ -d "${p}"/${hook}.d ]; then
                for a in "${p}"/${hook}.d/*; do
                    if [ -x "$a" -a ! -d "$a" ] && [[ "$a" != *~ ]]; then
                        echo "Running $hook hook: ${a}"
                        "${a}" "${hook}" \
                               "${cw_INSTANCE_role}" \
                               "${cw_CLUSTER_name}" \
                               "$@"
                    elif [[ "$a" != *~ ]]; then
                        echo "Skipping non-executable $hook hook: ${a}"
                    fi
                done
            else
                echo "No $hook hooks found in ${p}"
            fi
        fi
    done
}

customize_set_region() {
    if [ -z "${_REGION}" ]; then
        if network_is_ec2; then
            eval $(network_fetch_ec2_document | "${cw_ROOT}"/opt/jq/bin/jq -r '"_REGION=\(.region)"')
        else
            _REGION="${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}"
        fi
    fi
}

customize_set_machine_type() {
    if [ -z "${_MACHINE_TYPE}" ]; then
        _MACHINE_TYPE="$(network_fetch_ec2_metadata instance-type)"
    fi
}

customize_fetch_profile() {
    local s3cfg source target host manifest f s3cmd excludes
    s3cfg="$1"
    source="$2"
    target="$3"
    excludes="$4"
    mkdir -p "${target}"
    if [ "${s3cfg}" ]; then
        # Create bucket if it does not already exist
        "${cw_ROOT}"/opt/s3cmd/s3cmd -c ${s3cfg} mb "s3://${source%%/*}" &>/dev/null
        local args
        args=(--force -r)
        if [ -n "${excludes}" ] ; then
            args+=(--exclude)
            args+=(${excludes})
        fi
        "${cw_ROOT}"/opt/s3cmd/s3cmd -c ${s3cfg} ${args[@]} get "s3://${source}"/ "${target}"
        if rmdir "${target}" 2>/dev/null; then
            echo "No profile found for: ${source}"
            return 1
        fi
    else
        # fetch manifest file
        if [ "${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}" == "us-east-1" ]; then
            host=s3.amazonaws.com
        else
            host=s3-${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}.amazonaws.com
        fi
        manifest=$(curl -s -f https://${host}/${source}/manifest.txt)
        if [ "${manifest}" ] && ! echo "${manifest[*]}" | grep -q '<Error>'; then
            # fetch each file within manifest file
            for f in ${manifest}; do
                mkdir -p "${target}/$(dirname "$f")"
                if curl -s -f -o ${target}/${f} https://${host}/${source}/${f}; then
                    echo "Fetched: ${source}/${f}"
                else
                    echo "Unable to fetch: ${source}/${f}"
                    return 1
                fi
            done
        else
            echo "No manifest found for: ${source}"
            return 1
        fi
    fi
}

customize_fetch_machine_type() {
    local bucket prefix
    s3cfg=$1
    bucket="alces-flight-profiles-${_REGION}"
    if ! customize_is_s3_access_available "${s3cfg}" "${bucket}"; then
        echo "S3 access to '${bucket}' is not available.  Falling back to HTTP manifests."
        s3cfg=""
    fi
    prefix="${_SET_PREFIX}machines/${_MACHINE_TYPE}"
    echo "Retrieving machine type customizations from: ${bucket}/${prefix}"
    customize_fetch_profile "${s3cfg}" "${bucket}/${prefix}" \
                            "${cw_CLUSTER_CUSTOMIZER_path}"/machine-${_MACHINE_TYPE}
}

customize_fetch_features() {
    local bucket feature s3cfg
    s3cfg=$1
    bucket="alces-flight-profiles-${_REGION}"
    if ! customize_is_s3_access_available "${s3cfg}" "${bucket}"; then
        echo "S3 access to '${bucket}' is not available.  Falling back to HTTP manifests."
        s3cfg=""
    fi
    for feature in ${cw_CLUSTER_CUSTOMIZER_features}; do
        echo "Retrieving feature customizations from: ${bucket}/${_SET_PREFIX}features/$feature"
        customize_fetch_profile "${s3cfg}" "${bucket}"/${_SET_PREFIX}features/"${feature}" \
                                "${cw_CLUSTER_CUSTOMIZER_path}"/feature-${feature}
    done
}

customize_fetch_profiles() {
    local bucket profile
    if [ -z "${cw_CLUSTER_CUSTOMIZER_bucket}" ]; then
        if network_is_ec2; then
            bucket="alces-flight-$(network_ec2_hashed_account)"
        else
            echo "Unable to determine bucket name for customizations"
            return 0
        fi
    else
        bucket="${cw_CLUSTER_CUSTOMIZER_bucket#s3://}"
    fi
    if ! customize_is_s3_access_available "${s3cfg}" "${bucket}"; then
        echo "S3 access to '${bucket}' is not available.  Falling back to HTTP manifests."
        s3cfg=""
    fi
    for profile in ${cw_CLUSTER_CUSTOMIZER_profiles}; do
        echo "Retrieving customizations from: ${bucket}/customizer/$profile"
        customize_fetch_profile "${s3cfg}" "${bucket}"/customizer/"${profile}" \
                                "${cw_CLUSTER_CUSTOMIZER_path}"/profile-${profile} \
                                "*job-queue.d/*"
    done
}

customize_is_s3_access_available() {
    local s3cfg bucket
    s3cfg="$1"
    bucket="$2"
    "${cw_ROOT}"/opt/s3cmd/s3cmd -q -c ${s3cfg} ls "s3://${bucket}" 2>/dev/null
}

customize_set_feature_set() {
    if [ "${cw_CLUSTER_CUSTOMIZER_feature_set}" ]; then
        _SET_PREFIX="${cw_CLUSTER_CUSTOMIZER_feature_set}/"
    fi
}

customize_set_s3_config() {
  customize_set_region
  s3cfg="$(mktemp /tmp/cluster-customizer.s3cfg.XXXXXXXX)"
  cat <<EOF > "${s3cfg}"
[default]
access_key = "${cw_CLUSTER_CUSTOMIZER_access_key_id}"
secret_key = "${cw_CLUSTER_CUSTOMIZER_secret_access_key}"
security_token = ""
use_https = True
check_ssl_certificate = True
EOF
}

customize_clear_s3_config() {
  rm -f "${s3cfg}"
  unset s3cfg
}

customize_fetch() {
    customize_set_s3_config
    customize_set_feature_set
    mkdir -p "${cw_CLUSTER_CUSTOMIZER_path}"
    customize_set_machine_type
    if [ "${_MACHINE_TYPE}" ]; then
        customize_fetch_machine_type "${s3cfg}"
    fi
    customize_fetch_features "${s3cfg}"
    customize_fetch_profiles "${s3cfg}"
    chmod -R a+x "${cw_CLUSTER_CUSTOMIZER_path}"
    customize_clear_s3_config
}

customize_list_from_s3() {
    local all avail prohibited profile_type s3cfg url f
    s3cfg=$1
    url=$2
    profile_type=$3
    all=$("${cw_ROOT}"/opt/s3cmd/s3cmd -c ${s3cfg} --recursive ls "${url}")

    if [ "$profile_type" == "features" -a -n "${_SET_PREFIX}" ]; then
        f=6
    else
        f=5
    fi

    prohibited=$(echo "$all" | grep -E "(initialize|preconfigure)\.d" | cut -f$f -d'/' | uniq | grep -v '^$')
    avail=$(echo "$all" | cut -f$f -d'/' | uniq | grep -v '^$')

    customize_print_list_excluding "$avail" "$prohibited" ""
}

customize_list_from_http() {
  local all host prohibited source prefix index
  source="$1"
  prefix="$2"
  if [ "${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}" == "us-east-1" ]; then
      host=s3.amazonaws.com
  else
      host=s3-${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}.amazonaws.com
  fi
  index=$(curl -s -f https://${host}/${source}/)
  if [[ $? -eq 0 ]]; then
    all=$(echo "$index" | grep -oP '(?<=\<Key>'$prefix'\/)[^\<]+?(?=\/manifest.txt\<\/Key\>)')
    prohibited=$(echo "$index" | grep -oP '(?<=\<Key>'$prefix'\/)[^\<]+?(?=\/(initialize|preconfigure)\.d.*\<\/Key\>)')
    customize_print_list_excluding "$all" "$prohibited" ""
  else
    echo "HTTPS call failed, customization listing unavailable."
    return 1
  fi
}

customize_print_list_excluding() {
  local ex existing av avail found prefix
  avail="$1"
  existing="$2"
  prefix="$3"
  for av in $avail; do
    found=false
    for ex in $existing; do
      if [[ "$av" == "$ex" ]]; then
        found=true
        break
      fi
    done
    if [[ "$found" == false ]]; then
      echo "$prefix$av"
    fi
  done
}

customize_list_profiles() {
  local bucket existing avail
  if [ -z "${cw_CLUSTER_CUSTOMIZER_bucket}" ]; then
      if network_is_ec2; then
          bucket="alces-flight-$(network_ec2_hashed_account)"
      else
          echo "Unable to determine bucket name for customizations"
          return 0
      fi
  else
      bucket="${cw_CLUSTER_CUSTOMIZER_bucket#s3://}"
  fi
  existing=$(ls "${cw_CLUSTER_CUSTOMIZER_path}" | grep -Po "(?<=profile-).*")
  if ! customize_is_s3_access_available "${s3cfg}" "${bucket}"; then
      echo "S3 access to '${bucket}' is not available.  Falling back to HTTP manifests."
      s3cfg=""
      avail=$(customize_list_from_http "$bucket" "customizer")
  else
    avail=$(customize_list_from_s3 "$s3cfg" "s3://${bucket}/customizer" account)
  fi
  customize_print_list_excluding "$avail" "$existing" " - profile/"
}

customize_list_features() {
  local bucket s3cfg existing avail
  s3cfg="$1"
  bucket="alces-flight-profiles-${_REGION}"

  existing=$(ls "${cw_CLUSTER_CUSTOMIZER_path}" | grep -Po "(?<=feature-).*")

  if ! customize_is_s3_access_available "${s3cfg}" "${bucket}"; then
      echo "S3 access to '${bucket}' is not available.  Falling back to HTTP manifests."
      s3cfg=""
      avail=$(customize_list_from_http "$bucket" "${_SET_PREFIX}features")
  else
    avail=$(customize_list_from_s3 "$s3cfg" "s3://${bucket}/${_SET_PREFIX}features" features)
  fi
  customize_print_list_excluding "$avail" "$existing" " - feature/"
}

customize_list() {
  local repo_name tmpfile

  require customize-repository

  repo_name="$1"
  tmpfile=$(mktemp "/tmp/cluster-customizer.s3cfg.XXXXXXXX")

  if [[ "$repo_name" == "" ]]; then
    echo "No repo name specified"
  else
    customize_repository_index "$repo_name" > "$tmpfile"
    if [ "$?" == 0 ]; then
      customize_repository_list_profiles "$repo_name" "$tmpfile"
    else
      echo "Could not retrieve repository index."
    fi
    rm "$tmpfile"
  fi

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

customize_profile_can_be_installed() {
  local expression initCount s3cfg source
  s3cfg="$1"
  source="$2"

  expression="(initialize|preconfigure)\.d"

  if [ "$s3cfg" ]; then
    initCount=$("${cw_ROOT}"/opt/s3cmd/s3cmd -c ${s3cfg} ls "s3://${source}"/ | grep -E "$expression" | wc -l)
  else
    if [ "${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}" == "us-east-1" ]; then
        host=s3.amazonaws.com
    else
        host=s3-${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}.amazonaws.com
    fi
    initCount=$(curl -s -f https://${host}/${source}/manifest.txt | grep -E "$expression" | wc -l)
  fi

  if [[ $initCount == 0 ]]; then
    return 0
  else
    echo "Cannot apply profile. This profile requires installation before cluster initialization and does not support being applied while the cluster is running."
    return 1
  fi
}

customize_apply() {
  local bucket name type varname sourcepath excludes
  bucket="$1"
  name="$2"
  type="$3"
  excludes="$4"

  if ! customize_is_s3_access_available "${s3cfg}" "${bucket}"; then
      echo "S3 access to '${bucket}' is not available.  Falling back to HTTP manifests."
      s3cfg=""
  fi

  if [[ "$type" == "feature" ]] ; then
    varname="cw_CLUSTER_CUSTOMIZER_features"
    sourcepath="${_SET_PREFIX}features"
  else
    varname="cw_CLUSTER_CUSTOMIZER_profiles"
    sourcepath="customizer"
  fi

  if customize_profile_can_be_installed "$s3cfg" "${bucket}/${sourcepath}/$name"; then

    echo "Retrieving customization from: ${bucket}/${sourcepath}/$name"
    customize_fetch_profile "${s3cfg}" "${bucket}/${sourcepath}/$name" \
                            "${cw_CLUSTER_CUSTOMIZER_path}/${type}-${name}" \
                            "${excludes}"

    if [[ $? -eq 0 ]]; then
      sed -i "s/$varname=.*/$varname=\"${!varname} $name\"/" "$cw_ROOT"/etc/cluster-customizer.rc
      chmod -R a+x "${cw_CLUSTER_CUSTOMIZER_path}/${type}-${name}"
      echo "Running configure for $name"
      customize_run_hooks "configure:$type-$name"
      member_each _run_member_hooks "${members}" "member-join:$type-$name"
      return 0
    fi
  fi
  echo "Applying profile failed."
  return 1
}

customize_apply_profile() {
  local bucket profile_name
  profile_name="$1"

  customize_set_s3_config
  customize_set_feature_set

  if [ -z "${cw_CLUSTER_CUSTOMIZER_bucket}" ]; then
      if network_is_ec2; then
          bucket="alces-flight-$(network_ec2_hashed_account)"
      else
          echo "Unable to determine bucket name for customizations"
          return 0
      fi
  else
      bucket="${cw_CLUSTER_CUSTOMIZER_bucket#s3://}"
  fi

  echo "Applying profile $profile_name..."

  customize_apply "$bucket" "$profile_name" "profile" "job-queue.d/*"

  customize_clear_s3_config
}

customize_apply_feature() {
  local bucket feature_name
  feature_name="$1"

  customize_set_s3_config
  customize_set_feature_set

  bucket="alces-flight-profiles-${_REGION}"

  echo "Applying feature $feature_name..."

  customize_apply "$bucket" "$feature_name" "feature"

  customize_clear_s3_config
}
