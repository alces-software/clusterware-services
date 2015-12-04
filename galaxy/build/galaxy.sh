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
curl -L "https://github.com/galaxyproject/galaxy/archive/release_15.10.zip" -o /tmp/release_15.10.zip
unzip -d /tmp /tmp/release_15.10.zip >/dev/null

GALAXYDIR="${SERVICEDIR}/galaxy"
mv /tmp/galaxy-release_15.10 "${GALAXYDIR}"
install -Dm640 build/galaxy.ini "${GALAXYDIR}"/config/galaxy.ini
install -Dm644 build/job_conf.xml "${GALAXYDIR}"/config/job_conf.xml

pushd "${GALAXYDIR}"
cp config/tool_conf.xml.sample config/tool_conf.xml
mkdir shed-tool-deps

# This run will fail as there's no libdrmaa.so available
./run.sh
rm -f "${GALAXYDIR}"/config/job_conf.xml

# run in background
./run.sh &
GALAXYPID=$!
if [ "$GALAXYPID" ]; then
    # wait until it's listening on port
    while ps $GALAXYPID >/dev/null && ! ss -ln | grep -q 'LISTEN.*:6414 '; do
        sleep 5
    done
    curl -X POST --data 'create_user_button=Submit&email=admin%40alces.network&password=changeme&confirm=changeme&username=galaxy-admin' http://localhost:6414/user/create &>/dev/null
    # kill background process
    kill $GALAXYPID
    pkill -f "paster.py serve config/galaxy.ini"
fi

sed -i -e 's,^#database_connection = postgresql,database_connection = postgresql,g' -e 's,^database_connection = sqlite,#database_connection = sqlite,g' config/galaxy.ini
./run.sh &>/dev/null || true

patch <<EOF
--- lib/galaxy/jobs/runners/drmaa.py.orig	2015-11-30 19:39:17.000000000 +0000
+++ lib/galaxy/jobs/runners/drmaa.py	2015-12-03 18:24:48.002121062 +0000
@@ -138,6 +138,7 @@
         jt.workingDirectory = job_wrapper.working_directory
         jt.outputPath = ":%s" % ajs.output_file
         jt.errorPath = ":%s" % ajs.error_file
+        jt.joinFiles = False
 
         # Avoid a jt.exitCodePath for now - it's only used when finishing.
         native_spec = job_destination.params.get('nativeSpecification', None)
EOF

popd

rm -f /tmp/release_15.10.zip
