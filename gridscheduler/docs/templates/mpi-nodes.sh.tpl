#!/bin/bash -l
#@      cw_TEMPLATE[name]="MPI multiple node (GridScheduler)"
#@      cw_TEMPLATE[desc]="Submit a single job that spans multiple nodes where you want exclusive use of each node allocated."
#@ cw_TEMPLATE[copyright]="Copyright (C) 2009-2015 Alces Software Ltd."
#@   cw_TEMPLATE[license]="Creative Commons Attribution-ShareAlike 4.0 International"
#==============================================================================
# Copyright (C) 2009-2015 Alces Software Ltd.
#
# This work is licensed under a Creative Commons Attribution-ShareAlike
# 4.0 International License.
#
# See http://creativecommons.org/licenses/by-sa/4.0/ for details.
#==============================================================================
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#                         SGE SUBMISSION SCRIPT
#                        AVERAGE QUEUE TIME: Long
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#  >>>> OPERATIONAL DIRECTIVES - change these as required
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

#=====================
#  Working directory
#---------------------
# When enabled, this setting will cause your job to be executed in
# the current working directory - by default, this will be your home
# directory.
#
#$ -cwd

# Alternatively, if you need to specify an explicit working
# directory for your job, disable or remove the -cwd setting above
# and set a location here.
#
##$ -wd $HOME/sharedscratch/

#=========================
#  Environment variables
#-------------------------
# When enabled, this setting exports all variables present when the
# job is submitted.
#
#$ -V

#================
#  Output files
#----------------
# Merge STDERR into STDOUT
#
# Enable this option to merge the standard error output stream into
# standard output - this is usually the best option unless you have
# a specific need to keep the output streams separated.
#
#$ -j y

# Set an output file for STDOUT
#
# Specify a path to a file to contain the output from the standard
# output stream of your job script.
#
#$ -o $HOME/$JOB_NAME.$JOB_ID.output

# Set an output file for STDERR
#
# Specify a path to a file to contain the output from the standard
# error stream of your job script.
#
# This is not required if you have selected to merge the streams above.
#
##$ -e $HOME/$JOB_NAME.$JOB_ID.error

#============
#  Job name
#------------
# Set the name of your job - this will be shown in the process
# queue.
#
##$ -N myjob

#=======================
#  Email notifications
#-----------------------
# Set the destination email address for notifications.
#
##$ -M your.email@example.com

# Set the conditions under which you wish to be notified.
# (b:begin, e:end, a:aborted, s:suspended)
#
##$ -m beas

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#  >>>> RESOURCE REQUEST DIRECTIVES - always set these
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

#===================
#  Maximum runtime
#-------------------
# Expected RUNTIME
#
# Enter the expected runtime for your job.  Specification of a
# shorter runtime will cause the scheduler to be more likely to
# schedule your job sooner, but note that your job **will be
# terminated if it is still executing after the time specified**.
#
# Format: hours:minutes:seconds, e.g. `72:0:0` for 3 days.
#
#$ -l h_rt=72:0:0

#================
#  Project name
#----------------
# Specify project?
#
# If you have been allocated a project by your administrator or
# group leader, you should enable this setting and specify the
# project name.
#
# You may have been provided with a project to allow cluster usage
# to be metered or in order to increase the priority of the job in
# the queue allowing it to run sooner.
#
##$ -P default.prj

#================
#  Memory limit
#----------------
# Expected HARD MEMORY LIMIT (Per Node)
#
# Enter the expected memory usage of your job.  Specification of a
# smaller memory requirement will cause the scheduler to be more
# likely to schedule your job sooner, but note that your job **will
# be terminated if it exceeds the specified allocation**.
#
# Note that:
#
#  1. For this type of job you would usually request all available
#     memory of a node in order to prevent the job being terminated.
#
#  2. Without a suffix, this setting is interpreted as megabytes.
#     Specify a `G` suffix to request gigabytes. e.g. specify `61140`
#     or `60G` for 60 gigabytes.
#
#$ -l h_vmem=2G

#========================
#  Parallel environment
#------------------------
# Specify the parallel environment and number of nodes required for
# your job.
#
# You should request the parallel environment by name, followed by
# the number of nodes required.  For example `mpinodes-verbose 2`
# will allocate 2 nodes for the job.
#
# Note that requesting a larger number of nodes will mean that your
# job could take longer to launch.
#
#$ -pe mpinodes-verbose 2

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#  >>>> SET TASK ENVIRONMENT VARIABLES
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
# If necessary, set up further environment variables that are not
# specific to your workload here.
#
# The standard variables, JOB_ID, JOB_NAME, NHOSTS and NSLOTS are
# made available by the scheduler.

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#  >>>> YOUR WORKLOAD
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

#=======================
#  Environment modules
#-----------------------
# e.g.:
# module load apps/imb

# Load the OpenMPI module for access to `mpirun` command
module load mpi/openmpi

#===========================
#  Create output directory
#---------------------------
# Specify and create an output file directory.

OUTPUT_PATH="$(pwd)/${JOB_NAME}-outputs/$JOB_ID"
mkdir -p "$OUTPUT_PATH"

#===============================
#  Application launch commands
#-------------------------------
# Customize this section to suit your needs.

echo "Executing job commands, current working directory is $(pwd)"

# REPLACE THE FOLLOWING WITH YOUR APPLICATION COMMANDS

mpirun -np 2 -npernode 1 echo "This is an example job, I ran on $NHOSTS hosts and had exclusive access to the hosts on which I ran. My master thread ran on `hostname -s` as `whoami`" > $OUTPUT_PATH/test.output
echo "Output file has been generated, please check $OUTPUT_PATH/test.output"
