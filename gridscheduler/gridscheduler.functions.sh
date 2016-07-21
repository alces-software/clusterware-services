################################################################################
##
## Alces Clusterware - Scheduler function definitions
## Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
gridscheduler_features() {
    echo ":autoscaling:"
}

gridscheduler_setup_environment() {
    export MODULEPATH="${cw_ROOT}"/etc/modules
    eval $("${cw_ROOT}"/opt/Modules/bin/modulecmd bash purge)
    eval $("${cw_ROOT}"/opt/Modules/bin/modulecmd bash load services/gridscheduler)
}

gridscheduler_empty_nodes() {
    require ruby
    gridscheduler_setup_environment
    ruby_run <<RUBY
require 'rexml/document'
doc = REXML::Document.new(IO.popen('qstat -f -xml -q bynode.q@*'))
doc.each_element('//Queue-List') do |el|
  used = el.text('slots_used')
  name = el.text('name')
  state = el.text('state')
  if state != 'S' && used == "0"
    puts name.split('@').last.split('.').first
  end
end
RUBY
}

gridscheduler_disable_node() {
    local node
    node="$1"
    gridscheduler_setup_environment
    qmod -d "*@${node}" > /dev/null
}

gridscheduler_enable_node() {
    local node
    node="$1"
    gridscheduler_setup_environment
    qmod -e "*@${node}" > /dev/null
}

gridscheduler_parse_job_states() {
    local tgtfile cores_per_node
    tgtfile="$1"
    cores_per_node="$2"
    require ruby
    gridscheduler_setup_environment
    ruby_run <<RUBY > "${tgtfile}"
require 'rexml/document'
pending_job_ids = IO.popen("qstat -u '*' -s p | tail -n+3 | awk '{print \$1;}'").read.split("\n")
running_job_ids = IO.popen("qstat -u '*' -s r | tail -n+3 | awk '{print \$1;}'").read.split("\n")
nodes = 0.0
cores = 0
cores_per_node = ${cores_per_node:-2}
pending_job_ids.each do |jid|
  doc = REXML::Document.new(IO.popen("qstat -xml -j #{jid}"))
  slots = (doc.text('//JB_pe_range/ranges/RN_max') || 1).to_i
  pe = doc.text('//JB_pe')
  if pe == "mpinodes" || pe == "mpinodes-verbose"
    nodes += slots
    cores += (cores_per_node * slots)
  else
    cores += (slots || 1)
    nodes += ((slots || 1) * 1.0 / cores_per_node)
  end
end
results = {
  "gridscheduler_job_queue" => pending_job_ids.length,
  "gridscheduler_job_run" => running_job_ids.length,
  "gridscheduler_job_total" => pending_job_ids.length + running_job_ids.length,
  "gridscheduler_cores_req" => cores,
  "gridscheduler_nodes_req" => nodes.ceil
}
results.each do |k,v|
  puts "#{k}=#{v}"
end
RUBY
}

gridscheduler_write_node_resources() {
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
