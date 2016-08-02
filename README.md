# Alces Clusterware Services

Serviceware for [Alces Clusterware](https://github.com/alces-software/clusterware) that provide various services that can be plugged in to Clusterware to provide additional functionality.

## Installation

You should use these services in conjunction with Alces Clusterware.  Installation of Clusterware services occurs as part of the Alces Clusterware installation.  Refer to the Alces Clusterware documentation for details of how to install services and enable service components.

## Service overview

### `alces-access-manager-daemon`

Provides support for the Alces Access Manager appliance.

### `alces-flight-trigger`

Provides HTTP API and convention-driven directory structure for remote process to trigger scripts.

### `alces-flight-www`

Centralized web server based on NGINX which provides a convention-driven directory structure to allow other Serviceware components to easily plug in to a single HTTP service.

### `alces-storage-manager-daemon`

Provides support for the Alces Storage Manager appliance.

### `aws`

AWS Command Line Interface tool for managing AWS services.

### `clusterware-dropbox-cli`

API to the Dropbox file hosting service for use with the Alces Storage back-end for Dropbox.

### `galaxy`

Provides Galaxy, the open source, web-based platform for data intensive biomedical research.

### `gridscheduler`

Open Grid Scheduler, an open-source batch-queuing system for distributed resource management.

### `openlava`

OpenLava, a 100% free, open-source, LSF-compatible workload scheduler that supports a variety of HPC and analytic applications. 

### `openvpn`

Provides an OpenVPN server.

### `pbspro`

PBS Professional open source job scheduler.

### `s3cmd`

The command-line S3 client.

### `simp_le`

A simple Let's Encrypt client which can be used to request SSL certificates.

### `slurm`

Simple Linux Utility for Resource Management (Slurm), an open source, fault-tolerant, and highly scalable cluster management and job scheduling system for large and small Linux clusters.

### `torque`

TORQUE Resource Manager, providing control over batch jobs and distributed computing resources.

## Contributing

Fork the project. Make your feature addition or bug fix. Send a pull request. Bonus points for topic branches.

## Copyright and License

Creative Commons Attribution-ShareAlike 4.0 License, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2015-2016 Alces Software Ltd.

You should have received a copy of the license along with this work.  If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.

![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

Alces Clusterware Services by Alces Software Ltd is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

Based on a work at <https://github.com/alces-software/clusterware-services>.

Alces Clusterware Services is made available under a dual licensing model whereby use of the package in projects that are licensed so as to be compatible with the Creative Commons Attribution-ShareAlike 4.0 International License may use the package under the terms of that license. However, if these terms are incompatible with your planned use of this package, alternative license terms are available from Alces Software Ltd - please direct inquiries about licensing to [licensing@alces-software.com](mailto:licensing@alces-software.com).
