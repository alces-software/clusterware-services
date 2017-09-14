#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================
location /tutorials {
    try_files $uri @alces-web-terminal;
}
