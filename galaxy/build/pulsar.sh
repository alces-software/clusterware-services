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
export PYTHONPATH="${cw_ROOT}"/opt/galaxy/pulsar/lib/python${pyver}/site-packages
export CFLAGS=-I/opt/clusterware/opt/lib/include
export LIBRARY_PATH=/opt/clusterware/opt/lib/lib

mkdir -p "${cw_ROOT}"/opt/galaxy/pulsar/lib/python${pyver}/site-packages

easy_install --prefix="${cw_ROOT}"/opt/galaxy/pulsar pulsar-app
easy_install --prefix="${cw_ROOT}"/opt/galaxy/pulsar pyOpenSSL
easy_install --prefix="${cw_ROOT}"/opt/galaxy/pulsar drmaa

pushd "${cw_ROOT}"/opt/galaxy/pulsar/lib/python${pyver}/site-packages/pulsar_app-*.egg
patch -p0 <<EOF
--- pulsar/managers/util/job_script/DEFAULT_JOB_FILE_TEMPLATE.sh.orig	2015-12-03 16:07:24.561674962 +0000
+++ pulsar/managers/util/job_script/DEFAULT_JOB_FILE_TEMPLATE.sh	2015-12-03 16:08:58.462674935 +0000
@@ -4,11 +4,7 @@
 export GALAXY_SLOTS
 GALAXY_LIB="$galaxy_lib"
 if [ "$GALAXY_LIB" != "None" ]; then
-    if [ -n "$PYTHONPATH" ]; then
-        PYTHONPATH="$GALAXY_LIB:$PYTHONPATH"
-    else
-        PYTHONPATH="$GALAXY_LIB"
-    fi
+    PYTHONPATH="$GALAXY_LIB"
     export PYTHONPATH
 fi
 $env_setup_commands
--- pulsar/managers/base/base_drmaa.py.orig	2015-12-01 23:12:02.000000000 +0000
+++ pulsar/managers/base/base_drmaa.py	2015-12-03 18:20:38.832121246 +0000
@@ -51,6 +51,7 @@
             "jobName": self._job_name(job_id),
             "outputPath": ":%s" % stdout_path,
             "errorPath": ":%s" % stderr_path,
+            "joinFiles": False,
         }
         if self.native_specification:
             attributes["nativeSpecification"] = self.native_specification
EOF
popd

unset PYTHONPATH
unset CFLAGS
unset LIBRARY_PATH

sed -i -e "s,paster serve ,paster serve --pid-file=${pulsar_pidfile} --log-file=/var/log/galaxy/pulsar.log ,g" \
  "${cw_ROOT}"/opt/galaxy/pulsar/bin/pulsar
