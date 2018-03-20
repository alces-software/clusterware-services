# run-graphical-jobs(7) -- How to run graphical jobs (GridScheduler)

## DESCRIPTION

This guide will help you start your graphical applications in the
correct way within your compute environment.

## OVERVIEW

Graphical applications should be run within the compute environment by
submitting them to the job scheduler system.  Running your
applications in this way will provide them with access to scalable
resources.

## PROCEDURE

Login to your graphical desktop and start a new terminal shell. At
this point, you are logged in to a login node within the compute
environment - applications should be submitted to the HPC job
scheduler and not run on the login node directly.

To get an interactive session, use the `qrsh` command from a shell
window on your graphical desktop; you may use the same syntax as the
`qsub` command to request additional resources for your interactive
shell. For example, to request a `qrsh` session with access to 32GB of
RAM and a maximum runtime, use the command:

    [user@login1(cluster) ~]$ qrsh -l h_vmem=32G -l h_rt=72:0:0

You may also run graphical applications using `qrsh` to launch them;
for example, to run the graphical xclock application via the
scheduler, use the command:

    [user@login1(cluster) ~]$ qrsh xclock

## SEE ALSO

qrsh(1), qsub(1)

## LICENSE

This work is licensed under a Creative Commons Attribution-ShareAlike
4.0 International License.

See <http://creativecommons.org/licenses/by-sa/4.0/> for more
information.

## COPYRIGHT

Copyright (C) 2009-2015 Alces Software Ltd.
