################################################################################
##
## Alces Clusterware - Scheduler function definitions
## Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
slurm_features() {
    echo ":autoscaling:"
}

slurm_setup_environment() {
    export MODULEPATH="${cw_ROOT}"/etc/modules
    eval $("${cw_ROOT}"/opt/modules/bin/modulecmd bash purge)
    eval $("${cw_ROOT}"/opt/modules/bin/modulecmd bash load services/slurm)
}

slurm_empty_nodes() {
    slurm_setup_environment
    sinfo --states=idle --Format=nodehost | tail -n+2
}

slurm_disable_node() {
    local node
    node="$1"
    slurm_setup_environment
    scontrol update NodeName=${node} State=DRAIN Reason=autoscaling
}

slurm_enable_node() {
    local node
    node="$1"
    slurm_setup_environment
    scontrol update NodeName=${node} State=RESUME Reason=autoscaling
}

slurm_parse_job_states() {
    local tgtfile cores_per_node
    tgtfile="$1"
    cores_per_node="$2"
    require ruby
    slurm_setup_environment
    ruby_run <<RUBY > "${tgtfile}"
r = IO.popen("squeue -O state,numcpus,numnodes -h").read.split("\n").map do |l|
  {}.tap do |h|
    vals = l.split(/\s+/)
    h[:state], h[:cores], h[:nodes] = vals
  end
end
by_state = r.group_by { |o| o[:state] }
by_state['PENDING'] ||= []
by_state['RUNNING'] ||= []
cores_per_node = ${cores_per_node:-2}
results = {
  "slurm_job_queue" => by_state['PENDING'].length,
  "slurm_job_run" => by_state['RUNNING'].length,
  "slurm_job_total" => r.length,
  "slurm_cores_req" => by_state['PENDING'].reduce(0) { |memo, o| memo + o[:cores].to_i },
  "slurm_nodes_req" => by_state['PENDING'].reduce(0.0) do |memo, o|
     if (o[:cores].to_f / cores_per_node).ceil < o[:nodes].to_i
       memo + o[:nodes].to_i
     else
       memo + o[:cores].to_f / cores_per_node
     end
  end.ceil
}
results.each { |k,v| puts "#{k}=#{v}" }

# Now consider autoscaling groups (== (partitions - "all"))

groups = IO.popen("sinfo -h -o '%R'").read.split("\n")

group_results = {}

groups.each { |group|

  group_jobs = IO.popen("squeue -O state,numcpus,numnodes -h -p #{group}").read.split("\n").map do |l|
    {}.tap do |h|
      vals = l.split(/\s+/)
      h[:state], h[:cores], h[:nodes] = vals
    end
  end.select { |o| o[:state] == "PENDING" || o[:state] == "RUNNING" }

  group_results[group] = {
    :cores_req => group_jobs.reduce(0) { |memo, o| memo + o[:cores].to_i },
    :nodes_req => group_jobs.reduce(0.0) do |memo, o|
     if (o[:cores].to_f / cores_per_node).ceil < o[:nodes].to_i
       memo + o[:nodes].to_i
     else
       memo + o[:cores].to_f / cores_per_node
     end
    end.ceil
  }
}

all_partition = group_results.delete("all")
default_queue = "${default_queue}"
default_queue = "_default" if default_queue == "default"
if all_partition and !default_queue.empty?
  # Jobs outside a specific scaling group (e.g. in 'all') we add to the default
  # autoscaling group
  group_results[default_queue][:cores_req] += all_partition[:cores_req]
  group_results[default_queue][:nodes_req] += all_partition[:nodes_req]
end

group_results.each do |k,v|
  k = "default" if k == "_default"
  puts "slurm_queue_#{k.gsub(/[-\.]/, "_")}_cores_req=#{v[:cores_req]}"
  puts "slurm_queue_#{k.gsub(/[-\.]/, "_")}_nodes_req=#{v[:nodes_req]}"
end

RUBY
}

slurm_write_node_resources() {
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
