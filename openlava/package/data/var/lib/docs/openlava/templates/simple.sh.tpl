#!/bin/bash -l
#@          cw_TEMPLATE[name]="Simple serial (LSF/OpenLava)"
#@          cw_TEMPLATE[desc]="Submit a single job."
#@ cw_TEMPLATE[extended_desc]="Your job will be allocated a single core on the first available node."
#@     cw_TEMPLATE[copyright]="Copyright (C) 2016 Alces Software Ltd."
#@       cw_TEMPLATE[license]="Creative Commons Attribution-ShareAlike 4.0 International"
#==============================================================================
# Copyright (C) 2016 Alces Software Ltd.
#
# This work is licensed under a Creative Commons Attribution-ShareAlike
# 4.0 International License.
#
# See http://creativecommons.org/licenses/by-sa/4.0/ for details.
#==============================================================================
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#                         LSF SUBMISSION SCRIPT
#                       AVERAGE QUEUE TIME: Short
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#  >>>> OPERATIONAL DIRECTIVES - change these as required
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

#=====================
#  Working directory
#---------------------
# By default, your job will be executed in the current working
# directory on the remote host.  If the current working directory is
# not accessible on the execution host, the job will be executed in
# /tmp.
#
# Alternatively, if you need to specify an explicit working
# directory for your job set a location here.
#
##BSUB -cwd $HOME/sharedscratch/

#================
#  Output files
#----------------
# Set an output file for messages generated by your job script
#
# Specify a path to a file to contain the output from the standard
# output stream of your job script.  If you omit `-e` below,
# standard error will also be written to this file.
#
#BSUB -o job-%J.output

# Set an output file for STDERR
#
# Specify a path to a file to contain the output from the standard
# error stream of your job script.
#
# This is not required if you want to merge both output streams into
# the file specified above.
#
##BSUB -e job-%J.error

# Specify a directory for containing your output files
#
##BSUB -outdir %U/%J

#============
#  Job name
#------------
# Set the name of your job - this will be shown in the process
# queue.
#
#BSUB -J myjob

#=======================
#  Email notifications
#-----------------------
# Set the destination email address for notifications.
#
##BSUB -u your.email@example.com

# Send a job report by email when the job finishes.
#
##BSUB -N

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
# Format: hours:minutes, e.g. `72:0` for 3 days.
#
#BSUB -W 72:0

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
##BSUB -P default

#================
#  Memory limit
#----------------
# Expected HARD MEMORY LIMIT
#
# Enter the expected memory usage of your job.  Specification of a
# smaller memory requirement will cause the scheduler to be more
# likely to schedule your job sooner, but note that your job **may
# be terminated if it exceeds the specified allocation**.
#
# Note that by default this setting is interpreted as being specified
# in kilobytes.
# e.g. specify `4194304` for 4 gigabytes.
#
#BSUB -M 4194304

# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
#  >>>> SET TASK ENVIRONMENT VARIABLES
# ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
# If necessary, set up further environment variables that are not
# specific to your workload here.
#
# Several standard variables, such as LSB_JOBID, LSB_JOBNAME and
# LSB_HOSTS, are made available by the scheduler.

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

OUTPUT_PATH="$(pwd)/${LSB_JOBNAME}-outputs/$LSB_JOBID"
mkdir -p "$OUTPUT_PATH"

#===============================
#  Application launch commands
#-------------------------------
# Customize this section to suit your needs.

echo "Executing job commands, current working directory is $(pwd)"

# REPLACE THE FOLLOWING WITH YOUR APPLICATION COMMANDS

echo "This is an example job, I ran on `hostname -s` as `whoami`" > $OUTPUT_PATH/test.output
echo "Output file has been generated, please check $OUTPUT_PATH/test.output"