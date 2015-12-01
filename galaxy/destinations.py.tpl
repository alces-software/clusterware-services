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
from galaxy.jobs import JobDestination
from galaxy.jobs.mapper import JobMappingException
import os
import yaml

def pulsar_params_for(cfg, token):
    params = {}
    params['url'] = cfg['url']
    params['private_token'] = token
    if 'native' in cfg:
        params['submit_native_specification'] = cfg['native']
    return params

def drmaa_params_for(cfg):
    params = {}
    if 'native' in cfg:
        params['nativeSpecification'] = cfg['native']
    return params

# Dynamically determine which queue to use
def job_dispatcher(app, user_email, user, job, tool, tool_id):
    # read config and state files
    with open("_cw_ROOT_/etc/galaxy/destinations.yml", 'r') as stream:
        cfg = yaml.load(stream)

    # if we have pulsar(s) available, ship the job to the next available
    if 'pulsar' in cfg and len(cfg['pulsar']['targets']) > 0:
        try:
            with open("_cw_ROOT_/etc/galaxy/state.yml", 'r') as stream:
                state = yaml.load(stream)
            next_pulsar_idx = state['next_pulsar']
        except:
            state = {}
            next_pulsar_idx = 0

        pulsar_cfg = cfg['pulsar']
        # if we have a DRMAA pulsar, ship the job to that
        # if we have one or more pulsars available, ship to the next pulsar in the ring
        if pulsar_cfg['targets'][0]['type'] == 'drmaa':
            next_pulsar_idx = 0
        params = pulsar_params_for(pulsar_cfg['targets'][next_pulsar_idx], pulsar_cfg['token'])

        # update state
        if next_pulsar_idx + 1 == len(cfg['pulsar']['targets']):
            state['next_pulsar'] = 0
        else:
            state['next_pulsar'] = next_pulsar_idx + 1
        with file('_cw_ROOT_/etc/galaxy/state.yml', 'w') as stream:
            yaml.dump(state, stream)

        return JobDestination(runner='pulsar', params=params)


    # if we have DRMAA available, ship the job to that
    elif 'drmaa' in cfg:
        runner = 'drmaa_%s' % (cfg['drmaa']['type'])
        return JobDestination(runner=runner, params=drmaa_params_for(cfg['drmaa']))


    # if none of the above are available, use the local destination
    else:
        return 'local'
