################################################################################
##
## Alces Clusterware - Scheduler function definitions
## Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
pbspro_features() {
    echo ":autoscaling:"
}

pbspro_setup_environment() {
    export MODULEPATH="${cw_ROOT}"/etc/modules
    eval $("${cw_ROOT}"/opt/modules/bin/modulecmd bash purge)
    eval $("${cw_ROOT}"/opt/modules/bin/modulecmd bash load services/pbspro)
}

pbspro_empty_nodes() {
    pbspro_setup_environment
    pbsnodes -aSL | tail -n+3 | grep -E '\S+\s+free' | cut -f1 -d' ' | cut -f1 -d'.'
}

pbspro_disable_node() {
    local node
    node="$1"
    pbspro_setup_environment
    pbsnodes -o ${node}.$(hostname -d)
}

pbspro_enable_node() {
    local node
    node="$1"
    pbspro_setup_environment
    pbsnodes -r ${node}.$(hostname -d)
}

pbspro_parse_job_states() {
    local tgtfile cores_per_node
    tgtfile="$1"
    cores_per_node="$2"
    require ruby
    pbspro_setup_environment
    ruby_run <<RUBY > "${tgtfile}"
jobs = IO.popen("qstat -n1 | tail -n+6").read.split("\n")
pending_jobs = jobs.select {|l| l.split(/\s+/)[9] == 'Q'}
running_job_count = jobs.count {|l| l.split(/\s+/)[9] == 'R'}
cores_per_node = ${cores_per_node:-2}
cores_req = pending_jobs.reduce(0) {|memo,l| memo + l.split(/\s+/)[6].to_i}
nodes_req = pending_jobs.reduce(0) {|memo,l| memo + l.split(/\s+/)[5].to_i}
default_queue="${default_queue}".gsub(/[-\.]/, "_")
results = {
  "pbspro_job_queue" => pending_jobs.length,
  "pbspro_job_run" => running_job_count,
  "pbspro_job_total" => running_job_count + pending_jobs.length,
  "pbspro_cores_req" => cores_req,
  "pbspro_nodes_req" => nodes_req,
  "pbspro_queue_#{default_queue}_nodes_req" => nodes_req
}
results.each { |k,v| puts "#{k}=#{v}" }
RUBY
}

pbspro_write_node_resources() {
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
