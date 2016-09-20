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
problems. Once your job has run for the first time, you can use
`bjobs <JOB_ID>` to ascertain how much resource your job actually used
and then tune your request accordingly in future runs.

Requesting resources as close to your jobs requirements as possible
will ensure that your job is scheduled as quickly as possible. Jobs
that request more resource will potentially queue for longer as they
need to wait for more resources to become available. The scheduler can
use jobs with smaller resource requests to backfill if it knows that
the smaller job will complete before enough resources will become
available for a larger, potentially higher priority, job to
start. This allows users requesting the correct resources &mdash; in
particular `-W` (runtime) and `-R "rusage[mem=<n>]"` (maximum memory usage)
&mdash; to jump the queue and start their jobs more quickly.

## INTERACTIVE JOBS

Interactive jobs can be run via the scheduler using the interactive
shell command `bsub -Is bash`. Running the command will allocate you
a single slot on an available compute node and give you a shell on that
node. From there you can then load your required application modules and
start running.

Often when experimenting with a new application it can be useful to
start an interactive session to understand the way it behaves and the
command line options available before you write a job script.

Calling `bsub -Is bash` on its own will allocate all the default resource
limits, however you can request more resources for your interactive
session by specifying them on the command line. For example:

 * `-W 120`:

   How long (in minutes) you will potentially keep the session open
   for; the session will be terminated when this time is exceeded.

 * `-R "rusage[mem=4096]"`:

   How much memory (in MB) you will potentially want to use in this session;
   the session will be terminated if you use more than you
   request. Note that this request is per slot, so if you are
   requesting multiple slots/cores for your job, you should divide the
   total amount of memory you want to use by the number of slots you
   are requesting.

 * `-n 2`:

   Inform the scheduler that you intend to run a multi-core job across
   two cores.

Use the command `man bsub` for more specific information on interactive
session creation.


## BATCH (SCRIPTED) JOBS

Most HPC workflows can be scripted; the resulting job script may be
submitted to the HPC job scheduler to run multiple times, potentially
with different datasets each time. Your job scripts can include
scheduler instructions (either by placing scheduler tags directly in
your workflow script if your workflow script is written in bash or by
writing a bash submission script that calls your workflow script).

Your job submission scripts can be submitted to the HPC job scheduler
via the `bsub` command. You can provide options for your submitted job
either through the job submission command, or more reliably by including
them within your job submission script. Any submission directives included
within the job script must begin the line with:

  `#BSUB <option>`

You can submit a basic job script to the cluster scheduler with the
following example command:

  `bsub < my_example_job.sh`

Use the command `man bsub` for more specific information on using `bsub`.

## CHECKING JOB STATUS

You can view the status of the cluster scheduler queues, viewing information
about any running jobs. The cluster scheduler queue can be queried with the
following example command:

  `bjobs [job-ID]`

Use the command `bjobs` for more specific information on using `bjobs`.

## SEE ALSO

run-graphical-jobs, bsub(1), bjobs(1)

## LICENSE

This work is licensed under a Creative Commons Attribution-ShareAlike
4.0 International License.

See <http://creativecommons.org/licenses/by-sa/4.0/> for more
information.

## COPYRIGHT

Copyright (C) 2009-2016 Alces Software Ltd.
