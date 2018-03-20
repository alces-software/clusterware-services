#!/bin/bash -l
#@      cw_TEMPLATE[name]="Simple serial array (GridScheduler)"
#@      cw_TEMPLATE[desc]="Submit multiple, similar jobs. Each job will be allocated a single core on the first available node."
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
#                       AVERAGE QUEUE TIME: Short
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
# Expected HARD MEMORY LIMIT
#
# Enter the expected memory usage of your job.  Specification of a
# smaller memory requirement will cause the scheduler to be more
# likely to schedule your job sooner, but note that your job **will
# be terminated if it exceeds the specified allocation**.
#
# Note that without a suffix, this setting is interpreted as
# megabytes.  Specify a `G` suffix to request gigabytes.
# e.g. specify `4096` or `4G` for 4 gigabytes.
#
#$ -l h_vmem=1G

#=======================
#  Array configuration
#-----------------------
# How many tasks?
#
# For example 1-10 will run 10 jobs, numbered from 1 to 10.
#
#$ -t 1-10

# How many tasks to schedule at once?
#
# Please note that the total may be limited within your compute environment.
#
#$ -tc 5

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#  >>>> YOUR WORKLOAD
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

#=======================
#  Environment modules
#-----------------------
# e.g.:
# module load apps/imb

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

echo "This is an example array job, I was task number $SGE_TASK_ID and I ran on `hostname -s` as `whoami`" > $OUTPUT_PATH/test.output.$SGE_TASK_ID
echo "Output file has been generated, please check $OUTPUT_PATH/test.output"
