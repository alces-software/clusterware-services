<?xml version="1.0"?>
<!--
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
-->
<job_conf>
  <plugins>
    <plugin id="local" type="runner" load="galaxy.jobs.runners.local:LocalJobRunner" workers="_CORES_"/>
    <!--plugin id="drmaa_sge" type="runner" load="galaxy.jobs.runners.drmaa:DRMAAJobRunner">
      <param id="drmaa_library_path">_cw_ROOT_/opt/gridscheduler/lib/linux-x64/libdrmaa.so</param>
    </plugin-->
    <plugin id="pulsar" type="runner" load="galaxy.jobs.runners.pulsar:PulsarRESTJobRunner"/>
  </plugins>
  <handlers>
    <handler id="main"/>
  </handlers>
  <destinations default="dynamic">
    <destination id="dynamic" runner="dynamic">
      <param id="type">python</param>
      <param id="function">job_dispatcher</param>
    </destination>
    <destination id="local" runner="local"/>
  </destinations>
</job_conf>