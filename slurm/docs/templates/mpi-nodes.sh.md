# mpi-nodes(7) -- MPI multiple node

## DESCRIPTION

Submit a single job that spans multiple nodes where you want exclusive
use of each node allocated.

Choose this template if you intend to spawn multiple threads yourself
or intend to run an MPI application.  This method is often used for MPI
jobs where you need to specify the number of processes, machine file
and process allocation manually, rather than leave this up to the
scheduler.

Your job will be allocated the requested number of empty nodes. This
method should not be used for SMP (OpenMP) jobs.

Only use this method if you need exclusive use of each node allocated;
prefer a multiple slot ([mpi-slots](mpi-slots)) job for a shorter
queue time.

## SEE ALSO

mpi-slots

## LICENSE

This work is licensed under a Creative Commons Attribution-ShareAlike
4.0 International License.

See <http://creativecommons.org/licenses/by-sa/4.0/> for more
information.

## COPYRIGHT

Copyright (C) 2009-2017 Alces Software Ltd.
