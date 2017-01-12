################################################################################
##
## Alces Clusterware - Scheduler function definitions
## Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
gridscheduler_features() {
    echo ":autoscaling:configurable:"
}

gridscheduler_setup_environment() {
    export MODULEPATH="${cw_ROOT}"/etc/modules
    eval $("${cw_ROOT}"/opt/modules/bin/modulecmd bash purge)
    eval $("${cw_ROOT}"/opt/modules/bin/modulecmd bash load services/gridscheduler)
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

autoscaling_queues = IO.popen("qconf -sql | grep FlightComputeGroup").read.split("\n")

nodes = 0.0
cores = 0
cores_per_node = ${cores_per_node:-2}

specified_queue_nodes = {}
autoscaling_queues.each do |q|
  specified_queue_nodes[q] = { :nodes => 0.0, :cores => 0 }
end

pending_job_ids.each do |jid|
  doc = REXML::Document.new(IO.popen("qstat -xml -j #{jid}"))
  slots = (doc.text('//JB_pe_range/ranges/RN_max') || 1).to_i
  pe = doc.text('//JB_pe')

  specific_queue = doc.text('//JB_hard_queue_list/destin_ident_list/QR_name')
  counted = false

  if specific_queue
    autoscaling_queues.each do |q|
      if File.fnmatch(specific_queue, q)
        if pe == "mpinodes" || pe == "mpinodes-verbose"
          specified_queue_nodes[q][:nodes] += slots
          specified_queue_nodes[q][:cores] += (cores_per_node * slots)
        else
          specified_queue_nodes[q][:cores] += (slots || 1)
          specified_queue_nodes[q][:nodes] += ((slots || 1) * 1.0 / cores_per_node)
        end
        counted = true
        break
      end
    end
  end
  if !counted
    if pe == "mpinodes" || pe == "mpinodes-verbose"
      nodes += slots
      cores += (cores_per_node * slots)
    else
      cores += (slots || 1)
      nodes += ((slots || 1) * 1.0 / cores_per_node)
    end
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

specified_queue_nodes.each do |k,v|
  puts "gridscheduler_queue_#{k}_cores_req=#{v[:cores]}"
  puts "gridscheduler_queue_#{k}_nodes_req=#{v[:nodes].ceil}"
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

gridscheduler_set_allocation_strategy() {
    local strategy tmpfile
    strategy="$1"
    gridscheduler_setup_environment
    tmpfile="$(mktemp /tmp/gridscheduler.setup.XXXXXXXX)"
    qconf -ssconf > "${tmpfile}"
    case ${strategy} in
        packing)
            sed -i 's/^load_formula.*/load_formula slots/g' "${tmpfile}"
        ;;
        spanning)
            sed -i 's/^load_formula.*/load_formula np_load_avg/g' "${tmpfile}"
        ;;
        *)
            echo "unrecognized or unsupported allocation strategy: ${strategy}"
            errlvl=1
        ;;
    esac
    if [ -z "$errlvl" ]; then
        qconf -Msconf "${tmpfile}" 2>&1
        errlvl=$?
    fi
    rm -f "${tmpfile}"
    return $errlvl
}

gridscheduler_set_submission_strategy() {
    local strategy nodeattr
    strategy="$1"
    gridscheduler_setup_environment
    nodeattr="${cw_ROOT}/opt/genders/bin/nodeattr"
    if [ ! -x "${nodeattr}" ]; then
        echo "unable to change submission strategy as nodeattr is not installed; try 'alces service install pdsh' first"
        return 1
    fi
    case ${strategy} in
        all)
            for a in $(${nodeattr} -f ${cw_ROOT}/etc/genders -q all); do
                qconf -as "${a}"
            done
            if ! grep -q "^cw_CLUSTER_SGE_submission=" "${cw_ROOT}"/etc/cluster-sge.rc; then
                echo "cw_CLUSTER_SGE_submission=\"all\"" >> "${cw_ROOT}"/etc/cluster-sge.rc
            fi
        ;;
        master|none)
            if [ "${strategy}" == "master" ]; then
                disable_gender="slave"
                for a in $(${nodeattr} -f ${cw_ROOT}/etc/genders -q master); do
                    qconf -as "${a}"
                done
            else
                disable_gender="all"
            fi
            for a in $(${nodeattr} -f ${cw_ROOT}/etc/genders -q ${disable_gender}); do
                qconf -ds "${a}"
            done
            tmpfile="$(mktemp /tmp/gridscheduler.setup.XXXXXXXX)"
            grep -v "^cw_CLUSTER_SGE_submission=" "${cw_ROOT}"/etc/cluster-sge.rc > \
                 "${tmpfile}"
            cat "${tmpfile}" > "${cw_ROOT}"/etc/cluster-sge.rc
            rm -f "${tmpfile}"
        ;;
        *)
            echo "unrecognized or unsupported submission strategy: ${strategy}"
            return 1
        ;;
    esac
}

gridscheduler_status() {
    local allocation_strategy submission_strategy
    gridscheduler_setup_environment 2>/dev/null
    allocation_strategy=$(qconf -ssconf | grep "load_formula" | sed 's/\S*\s*\(\S*\)/\1/')
    if [ "$allocation_strategy" == "np_load_avg" ]; then
        allocation_strategy="spanning"
    else
        allocation_strategy="packing"
    fi
    printf "%35s: %s\n" "Allocation strategy" "${allocation_strategy}"

    submission_strategy=$(qconf -ss 2>/dev/null| wc -l)
    if [ "$submission_strategy" == 1 ]; then
        submission_strategy="master"
    elif [ "$submission_strategy" == 0 ]; then
        submission_strategy="none"
    else
        submission_strategy="all"
    fi
    printf "%35s: %s\n" "Submission strategy" "${submission_strategy}"
}
