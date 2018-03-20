# mpi-slots(7) -- MPI multiple slot

## DESCRIPTION

Submit a job that has multiple processes that may span multiple nodes.

Choose this template if you intend to spawn multiple threads yourself
or intend to run an MPI application.

Your job will be allocated the requested number of slots/cores, which
may or may not be on the same node. This method should not be used for
SMP (OpenMP) jobs.

## LICENSE

This work is licensed under a Creative Commons Attribution-ShareAlike
4.0 International License.

See <http://creativecommons.org/licenses/by-sa/4.0/> for more
information.

## COPYRIGHT

Copyright (C) 2009-2015 Alces Software Ltd.
