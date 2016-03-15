# run-jobs(7) -- How to run jobs

## DESCRIPTION

Applications available within the compute environment may run in
either an interactive or a batch mode. This guide explains the
difference between these two types of execution and how they interact
with the job scheduler.

## OVERVIEW

Some applications installed within the compute environment are
interactive; this means that to run the application requires you to be
logged in with an interactive session. When that sessions terminates -
so does the application. These are typically applications such as
interactive command line tools or graphical tools. For more
information on running graphical jobs refer to the "How to run
graphical jobs" guide ([run-graphical-jobs](run-graphical-jobs)).

However, some applications are non-interactive and you are able to
pass them a number of command-line parameters (for example input and
output files) and they then run for a number of minutes / hours / days
processing data.

## THE SCHEDULER

All jobs to be executed within the compute environment must be
submitted through the job scheduler. This ensures fair usage as well
as making sure your job gets the best of the available resources
allocated to it. Whilst you can login to the compute nodes directly to
check on your jobs (via `ssh`), any processes on compute nodes that
are run outside of the scheduler are automatically swept periodically.

When submitting new job requests to the scheduler, you should make
your best guess for the resources it will require. If you find the job
gets terminated, increase your resource request to allow your job to
run. It's often worth starting with the defaults as these are usually
sufficient for most applications and then alter them if you have
problems. Once your job has run for the first time, you can use `qacct
-j <JOB_ID>` to ascertain how much resource your job actually used and
then tune your request accordingly in future runs.

Requesting resources as close to your jobs requirements as possible
will ensure that your job is scheduled as quickly as possible. Jobs
that request more resource will potentially queue for longer as they
need to wait for more resources to become available. The scheduler can
use jobs with smaller resource requests to backfill if it knows that
the smaller job will complete before enough resources will become
available for a larger, potentially higher priority, job to
start. This allows users requesting the correct resources &mdash; in
particular `h_rt` (runtime) and `h_vmem` (maximum memory usage)
&mdash; to jump the queue and start their jobs more quickly.

## INTERACTIVE JOBS

Interactive jobs can be run via the scheduler using the interactive
shell command `qrsh`. Running `qrsh` will allocate you a single slot
on an available compute node and give you a shell on that node. From
there you can then load your required application modules and start
running.

Often when experimenting with a new application it can be useful to
start an interactive session to understand the way it behaves and the
command line options available before you write a job script.

Calling `qrsh` on its own will allocate all the default resource
limits, however you can request more resources for your `qrsh` session
by specifying them on the command line. For example:

 * `-l h_rt=72:0:0`:

   How long you will potentially keep the session open for (hh:mm:ss);
   the session will be terminated when this time is exceeded

 * `-l h_vmem=4g`:

   How much memory you will potentially want to use in this session;
   the session will be terminated if you use more than you
   request. Note that this request is per slot, so if you are
   requesting multiple slots/cores for your job, you should divide the
   total amount of memory you want to use by the number of slots you
   are requesting.

 * `-pe smp 2`:

   Inform the scheduler that you intend to run a multi-core job across
   two cores

Use the command `man qrsh` for more specific information on using
`qrsh`.

## BATCH (SCRIPTED) JOBS

Most HPC workflows can be scripted; the resulting job script may be
submitted to the HPC job scheduler to run multiple times, potentially
with different datasets each time. Your job scripts can include
scheduler instructions (either by placing scheduler tags directly in
your workflow script if your workflow script is written in bash or by
writing a bash submission script that calls your workflow script).

Your job submission scripts can be submitted to the HPC job scheduler
via the `qsub` command.

There are some example job submission scripts for this compute
environment. Use the `alces template` tool to find out more about them
and to copy them to your work directory before modifying them to meet
your requirements:

 * `simple`:

   A simple job script for submitting single thread workflows.

 * `mpi-slots`:

   A job script to run workflows/applications that will run on
   multiple cores which don't necessarily have to be on the same
   compute node (e.g. MPI).

 * `mpi-nodes`:

   Similar to `mpi-slots` but with exclusive use of each allocated
   node.

 * `smp`:

   A job script to run workflows/applications that will run on
   multiple cores on the same compute node, limited by the number of
   cores in the node.

 * `simple-array`:

   A job script to submit an array of similar jobs as one.

Use the command `man qsub` for more specific information on using
`qsub`.

## SEE ALSO

run-graphical-jobs, qacct(1), qsub(1), qrsh(1)

## LICENSE

This work is licensed under a Creative Commons Attribution-ShareAlike
4.0 International License.

See <http://creativecommons.org/licenses/by-sa/4.0/> for more
information.

## COPYRIGHT

Copyright (C) 2009-2015 Alces Software Ltd.
