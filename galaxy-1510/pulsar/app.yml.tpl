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
---
managers:
  _default_:
    type: queued_python
    num_concurrent_jobs: '*'
#  drmaa:
#    type: queued_drmaa
#    min_polling_interval: 0.5
staging_directory: _cw_ROOT_/var/lib/galaxy-1510/pulsar/files/staging
job_directory_mode: '0777'
private_token: _SECRET_
persistence_directory: _cw_ROOT_/var/lib/galaxy-1510/pulsar/files/persisted_data
assign_ids: uuid
tool_dependency_dir: _cw_ROOT_/var/lib/galaxy-1510/pulsar/shed-tool-deps
