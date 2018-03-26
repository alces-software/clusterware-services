# run-graphical-jobs(7) -- How to run graphical jobs (TORQUE)

## DESCRIPTION

This guide will help you start your graphical applications in the correct way within your compute environment.

## OVERVIEW

Graphical applications should be run within the compute environment by submitting them to the job scheduler system. Running your applications in this way will provide them with access to scalable resources.

## PROCEDURE

Login to your graphical desktop and start a new terminal shell. At this point, you are logged in to a login node within the compute environment - applications should be submitted to the HPC job scheduler and not run on the login node directly.

To gain an interactive session on one of the available cluster compute hosts - use the following example command:

    `qsub -I`

You may use the same syntax as the `sbatch` command to request additional resources for your interactive shell. For example, to request an interactive session with access to 32GB of RAM and a maximum runtime of 72 hours, use the following command:

    `qsub -l walltime=72:00:00,mem=32768mb -I`

## SEE ALSO

qsub(1), qstat(1)

## LICENSE

This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.

See <http://creativecommons.org/licenses/by-sa/4.0/> for more information.

## COPYRIGHT

Copyright (C) 2009-2016 Alces Software Ltd.
