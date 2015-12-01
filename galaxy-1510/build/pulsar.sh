#!/bin/bash
#==============================================================================
# Copyright (C) 2015 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# Alces Clusterware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Clusterware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware, please visit:
# https://github.com/alces-software/clusterware
#==============================================================================
export PYTHONPATH="${cw_ROOT}"/opt/galaxy-1510/pulsar/lib/python${pyver}/site-packages
export CFLAGS=-I/opt/clusterware/opt/lib/include
export LIBRARY_PATH=/opt/clusterware/opt/lib/lib

mkdir -p "${cw_ROOT}"/opt/galaxy-1510/pulsar/lib/python${pyver}/site-packages

easy_install --prefix="${cw_ROOT}"/opt/galaxy-1510/pulsar pulsar-app
easy_install --prefix="${cw_ROOT}"/opt/galaxy-1510/pulsar pyOpenSSL
easy_install --prefix="${cw_ROOT}"/opt/galaxy-1510/pulsar drmaa

unset PYTHONPATH
unset CFLAGS
unset LIBRARY_PATH

sed -i -e "s,paster serve ,paster serve --pid-file=${pulsar_pidfile} --log-file=/var/log/galaxy/pulsar.log ,g" \
  "${cw_ROOT}"/opt/galaxy-1510/pulsar/bin/pulsar
