#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# All rights reserved, see LICENSE.txt.
#==============================================================================
location /terminal/socket.io {
    proxy_connect_timeout 7d;
    proxy_send_timeout 7d;
    proxy_read_timeout 7d;
    proxy_pass http://localhost:26399/terminal/socket.io;
    proxy_http_version 1.1;
    proxy_set_header upgrade $http_upgrade;
    proxy_set_header connection "upgrade";
    proxy_buffering off;
    access_log /var/log/alces-flight-www/alces-web-terminal-websockets-access.log;
    error_log  /var/log/alces-flight-www/alces-web-terminal-websockets-error.log;
}
