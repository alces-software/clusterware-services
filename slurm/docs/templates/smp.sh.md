# smp(7) -- SMP multiple slot

## DESCRIPTION

Submit a job that has multiple processes where all processes need to
reside on a single node.

Choose this template if you intend to spawn multiple threads yourself,
intend to run an SMP (OpenMP) application, or you know you application
spawns multiple threads internally where each can run on a different
CPU core.

Your job will be allocated the requested number of slots/cores, which
will always be on the same node.

You may only request the same number of slots as the maximum core
count for a single machine in your compute environment.

## LICENSE

This work is licensed under a Creative Commons Attribution-ShareAlike
4.0 International License.

See <http://creativecommons.org/licenses/by-sa/4.0/> for more
information.

## COPYRIGHT

Copyright (C) 2009-2017 Alces Software Ltd.
