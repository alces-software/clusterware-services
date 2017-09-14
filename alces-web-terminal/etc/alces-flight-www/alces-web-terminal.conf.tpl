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
    proxy_pass http://localhost:25288/terminal/socket.io;
    proxy_http_version 1.1;
    proxy_set_header upgrade $http_upgrade;
    proxy_set_header connection "upgrade";
    proxy_buffering off;
    access_log /var/log/alces-flight-www/alces-web-terminal-websockets-access.log;
    error_log  /var/log/alces-flight-www/alces-web-terminal-websockets-error.log;
}

location @alces-web-terminal {
    proxy_pass http://127.0.0.1:25288;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_redirect off;
}
