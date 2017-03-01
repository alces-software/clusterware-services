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
require files
require network

job_queue_bucket_path() {
    local queue relative_path
    queue="$1"
    relative_path="$2"

    if [ "${relative_path}" == "" ] ; then
        echo "${BUCKET}"/customizer/"${queue}"/job-queue.d/"${cw_CLUSTER_name}"
    else
        echo "${BUCKET}"/customizer/"${queue}"/job-queue.d/"${cw_CLUSTER_name}"/"${relative_path}"
    fi
}

job_queue_work_dir_path() {
    local queue relative_path
    queue="$1"
    relative_path="$2"

    if [ "${relative_path}" == "" ] ; then
        echo "${WORK_DIR}"/"${queue}"
    else
        echo "${WORK_DIR}"/"${queue}"/"${relative_path}"
    fi
}

# Adds job queue customizers to the `job_queues` array.
job_queue_get_job_queues() {
    local customizer all_customizers queue_customizers
    job_queue_s3cmd_setup

    all_customizers=$( "${cw_ROOT}"/opt/s3cmd/s3cmd ls --recursive "${BUCKET}/customizer/" )
    queue_customizers=$( echo "${all_customizers}" \
        | grep "${BUCKET}/customizer/[^/]*/job-queue.d/" \
        | cut -d/ -f5 \
        | uniq
    )
    for customizer in ${queue_customizers} ; do 
        job_queues+=("${customizer}")
    done
}

job_queue_s3cmd_setup() {
    files_load_config cluster-customizer
    files_load_config config config/cluster

    BUCKET="${cw_CLUSTER_CUSTOMIZER_bucket:-s3://alces-flight-$(network_ec2_hashed_account)}"
    export AWS_ACCESS_KEY_ID="${cw_CLUSTER_CUSTOMIZER_access_key_id}"
    export AWS_SECRET_ACCESS_KEY="${cw_CLUSTER_CUSTOMIZER_secret_access_key}"
}

# Download any custom job handling script for the queue.
job_queue_get_job_handling_customizations() {
    local queue s3_pending_dir local_pending_dir
    queue="$1"
    s3_pending_dir="${BUCKET}"/customizer/"${queue}"/share/
    local_pending_dir="${WORK_DIR}"/customizer/"${queue}"/share/

    mkdir -p "${local_pending_dir}"
    "${cw_ROOT}"/opt/s3cmd/s3cmd get --recursive --quiet ${s3_pending_dir} ${local_pending_dir}
}

job_queue_get_pending_jobs() {
    local queue s3_pending_dir local_pending_dir
    queue="$1"
    s3_pending_dir="$(job_queue_bucket_path "${queue}" pending/)"
    local_pending_dir="$(job_queue_work_dir_path "${queue}" pending/)"

    mkdir -p "${local_pending_dir}"
    "${cw_ROOT}"/opt/s3cmd/s3cmd get --recursive --quiet ${s3_pending_dir} ${local_pending_dir}
}

job_queue_save_job_output() {
    local queue output_dir job_id
    queue=$1
    job_id=$2
    output_dir=$3

    "${cw_ROOT}"/opt/s3cmd/s3cmd put --quiet --recursive \
        $(job_queue_work_dir_path "${queue}" "${output_dir}"/"${job_id}"/"$(hostname)") \
        $(job_queue_bucket_path "${queue}" "${output_dir}"/"${job_id}")/
}

# If there are any objects already stored with job_id, the job is invalid.  We
# don't want to overwrite any previous output.
job_queue_validate_job_id() {
    local queue job_id rejected_file existing
    queue=$1
    job_id=$2
    rejected_file=$3

    existing=$( "${cw_ROOT}"/opt/s3cmd/s3cmd ls \
        $(job_queue_bucket_path "${queue}" completed/"${job_id}"/"$(hostname)") \
        | wc -l
    )

    if [ $existing -ne 0 ] ; then
        mkdir -p $(dirname $rejected_file)
        echo "Job id ${job_id} previously used" > $rejected_file
        return 1
    fi
}

job_queue_validate_job_file() {
    local queue job_file rejected_dir rejected_file custom_validation_file
    local exit_code errors
    queue=$1
    job_file=$2
    rejected_dir=$3
    rejected_file=$4
    custom_validation_file="${WORK_DIR}"/customizer/"${queue}"/share/validate-job

    if [ -f "${custom_validation_file}" ] ; then
        chmod +x "${custom_validation_file}"
        errors=$( "${custom_validation_file}" "${job_file}" "${rejected_dir}" )
        exit_code=$?
        if [ $exit_code -ne 0 ] ; then
            mkdir -p $( dirname "${rejected_file}" )
            echo "${errors}" > "${rejected_file}"
        fi
        return $exit_code
    else
        # Job files are valid by default.
        return 0
    fi
}

job_queue_execute_job() {
    local queue job_file status_file output_dir custom_job_runner exit_code
    queue=$1
    job_file=$2
    status_file=$3
    output_dir=$4
    custom_job_runner="${WORK_DIR}"/customizer/"${queue}"/share/process-job
    files_load_config instance config/cluster

    if [ -f "${custom_job_runner}" ] ; then
        # If there is a custom job runner, use it to run the job file. 
        chmod +x "${custom_job_runner}"
        "${custom_job_runner}" \
            "${job_file}" \
            "${output_dir}" \
            "${cw_INSTANCE_role}" \
            "${cw_CLUSTER_name}" \
            ${ARGS}
        exit_code=$?
    else
        # If there is not a custom job runner, try executing the job file.
        chmod +x "${job_file}"
        "${job_file}" "${cw_INSTANCE_role}" "${cw_CLUSTER_name}" ${ARGS}
        exit_code=$?
    fi
    echo $exit_code > "${status_file}"
    return $exit_code
}


job_queue_process_pending_jobs() {
    local queue job_file job_id exit_code
    local output_dir log_file status_file
    local rejected_dir rejected_file
    queue="$1"

    echo "$( ls "$(job_queue_work_dir_path "${queue}" pending)" | wc -l ) pending job(s) found"
    for job_id in $( ls -tr "$(job_queue_work_dir_path "${queue}" pending)" ) ; do
        echo "Processing job ${job_id}"
        job_file="$(job_queue_work_dir_path "${queue}" pending/${job_id})"

        output_dir="$(job_queue_work_dir_path "${queue}" completed/${job_id}/$(hostname))"
        log_file="${output_dir}"/logs
        status_file="${output_dir}"/status

        rejected_dir="$(job_queue_work_dir_path "${queue}" rejected/${job_id}/$(hostname))"
        rejected_file="${rejected_dir}"/reason

        # mark_job_file_as_in_progress

        echo "Validating job ${job_id}"
        job_queue_validate_job_id "${queue}" "${job_id}" $rejected_file
        exit_code=$?
        if [ $exit_code -eq 0 ] ; then
            job_queue_validate_job_file "${queue}" $job_file $rejected_dir $rejected_file
            exit_code=$?
        fi
        if [ $exit_code -ne 0 ] ; then
            echo "Rejected job ${job_id}"
            job_queue_save_job_output "${queue}" "${job_id}" rejected
            job_queue_delete_job "${queue}" "${job_id}"
        else
            mkdir -p $(dirname $log_file)
            job_queue_execute_job "${queue}" $job_file $status_file $output_dir >"${log_file}" 2>&1
            exit_code=$?
            if [ $exit_code -ne 0 ] ; then
                echo "Error during execution of ${job_id}"
            else
                echo "Successfully executed job ${job_id}"
            fi
            job_queue_save_job_output "${queue}" "${job_id}" completed
            job_queue_delete_job "${queue}" "${job_id}"
        fi
    done
}

job_queue_process_queues() {
    local BUCKET WORK_DIR ARGS queue job_queues
    ARGS="$@"
    job_queues=()
    WORK_DIR=$( mktemp -d -p /tmp cluster-job-queue.XXXXXXXXXXXX )

    job_queue_s3cmd_setup
    echo "Getting job queues"
    job_queue_get_job_queues
    echo "Found ${#job_queues[@]} job queues"
    for queue in ${job_queues[@]}; do
        echo "Processing cluster job queue ${queue}"
        echo "Getting customization scripts for ${queue}"
        job_queue_get_job_handling_customizations "${queue}"
        echo "Getting pending jobs for ${queue}"
        job_queue_get_pending_jobs "${queue}"
        job_queue_process_pending_jobs "${queue}"
    done

    rm -rf "${WORK_DIR}"
}

job_queue_list_queues() {
    local job_queues q queue
    job_queues=()
    queue="$1"

    job_queue_get_job_queues
    for q in ${job_queues[@]} ; do
        echo $q
    done
}

job_queue_list_jobs_in_queue() {
    local queue job_status s3_prefix
    queue="$1"
    job_status="$2"

    job_queue_s3cmd_setup
    s3_prefix=$(job_queue_bucket_path "${queue}" "${job_status}"/ )

    "${cw_ROOT}"/opt/s3cmd/s3cmd ls ${s3_prefix} \
        | rev \
        | cut -d/ -f1 \
        | rev
}

job_queue_put() {
    local queue job_file job_id s3_key
    queue="$1"
    job_file="$2"
    job_id="$3"

    job_queue_s3cmd_setup
    s3_key=$(job_queue_bucket_path "${queue}" pending/"${job_id}" )

    "${cw_ROOT}"/opt/s3cmd/s3cmd put --quiet ${job_file} ${s3_key}
}

job_queue_list_output_files() {
    local queue job_id s3_key s3cmd_args job_status
    queue="$1"
    job_id="$2"

    job_queue_s3cmd_setup
    job_status=$(job_queue_get_job_status "${queue}" "${job_id}")
    s3_key=$(job_queue_bucket_path "${queue}" "${job_status}"/"${job_id}"/ )

    "${cw_ROOT}"/opt/s3cmd/s3cmd ls --recursive ${s3_key} \
        | awk '{print $4}' \
        | sed "s ${s3_key}  g"
}

job_queue_get_output_file() {
    local queue job_id output_file job_status s3_key s3cmd_args
    queue="$1"
    job_id="$2"
    output_file="$3"
    s3cmd_args=(--quiet)

    job_queue_s3cmd_setup
    job_status=$(job_queue_get_job_status "${queue}" "${job_id}")
    s3_key=$(job_queue_bucket_path "${queue}" "${job_status}"/"${job_id}"/"${output_file}" )

    "${cw_ROOT}"/opt/s3cmd/s3cmd get ${s3cmd_args[@]} ${s3_key} -
}

job_queue_get_job_status() {
    local queue job_id s3_key s3cmd_args
    queue="$1"
    job_id="$2"

    job_queue_s3cmd_setup

    s3_key=$(job_queue_bucket_path "${queue}" pending/"${job_id}" )
    if [ $( "${cw_ROOT}"/opt/s3cmd/s3cmd ls ${s3_key} | wc -l ) -ne 0 ] ; then
        echo "pending"
        return 0
    fi

    s3_key=$(job_queue_bucket_path "${queue}" completed/"${job_id}" )
    if [ $( "${cw_ROOT}"/opt/s3cmd/s3cmd ls ${s3_key} | wc -l ) -ne 0 ] ; then
        echo "completed"
        return 0
    fi

    s3_key=$(job_queue_bucket_path "${queue}" rejected/"${job_id}" )
    if [ $( "${cw_ROOT}"/opt/s3cmd/s3cmd ls ${s3_key} | wc -l ) -ne 0 ] ; then
        echo "rejected"
        return 0
    fi
}

job_queue_delete_job() {
    local queue job_id s3_key s3cmd_args
    queue="$1"
    job_id="$2"

    job_queue_s3cmd_setup
    s3_key=$(job_queue_bucket_path "${queue}" pending/"${job_id}" )
    "${cw_ROOT}"/opt/s3cmd/s3cmd rm --quiet ${s3_key}
}
