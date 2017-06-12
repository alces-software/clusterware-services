################################################################################
##
## Alces Clusterware - Scheduler function definitions
## Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
openlava_features() {
    echo ":autoscaling:"
}

openlava_setup_environment() {
    export MODULEPATH="${cw_ROOT}"/etc/modules
    eval $("${cw_ROOT}"/opt/modules/bin/modulecmd bash purge)
    eval $("${cw_ROOT}"/opt/modules/bin/modulecmd bash load services/openlava)
}

openlava_empty_nodes() {
    openlava_setup_environment
    bhosts | tail -n+2 | awk '{print $5 " " $1}' | grep "^0 " | cut -f2 -d' '
}

openlava_disable_node() {
    local node
    node="$1"
    openlava_setup_environment
    badmin hclose ${node}
}

openlava_enable_node() {
    local node
    node="$1"
    openlava_setup_environment
    badmin hopen ${node}
}

openlava_parse_job_states() {
    local tgtfile cores_per_node
    tgtfile="$1"
    cores_per_node="$2"
    require ruby
    openlava_setup_environment
    ruby_run <<RUBY > "${tgtfile}"
jobs = IO.popen("bjobs -u all -noheader").read.split("\n")
queues = IO.popen("bqueues | tail -n+2").read.split("\n")
pending_jobs = jobs.count {|l| l.split(/\s+/)[2] == 'PEND'}
running_jobs = jobs.count {|l| l.split(/\s+/)[2] == 'RUN'}
cores_per_node = ${cores_per_node:-2}
cores_req = queues.reduce(0) {|memo,l| memo + l.split(/\s+/)[8].to_i}
default_queue="${default_queue}".gsub(/[-\.]/, "_")
results = {
  "openlava_job_queue" => pending_jobs,
  "openlava_job_run" => running_jobs,
  "openlava_job_total" => jobs.length,
  "openlava_cores_req" => cores_req,
  "openlava_nodes_req" => ((cores_req * 1.0) / cores_per_node).ceil,
  "openlava_queue_#{default_queue}_nodes_req" => ((cores_req * 1.0) / cores_per_node).ceil,
}
results.each { |k,v| puts "#{k}=#{v}" }
RUBY
}

openlava_write_node_resources() {
    local target
    target="$1"
    require ruby
    ruby_run <<RUBY
require 'json'

config = {"tags" => {}}
config["tags"]["slots"] = $(grep -c '^processor\s*: [0-9]*$' /proc/cpuinfo).to_s
ram_kb = $(grep 'MemTotal' /proc/meminfo | awk '{print $2};')
ram_gb = (ram_kb / 1_048_576)
config["tags"]["ram_gb"] = ram_gb.to_s
File.write('${target}', config.to_json)
RUBY
}
