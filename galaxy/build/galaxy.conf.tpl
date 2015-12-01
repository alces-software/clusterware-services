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
upstream galaxy_app {
    server localhost:6414;
}

server {
    listen 64443 ssl;
    server_name localhost;
    client_max_body_size 0;

    ssl_certificate _ROOT_/etc/ssl/clusterware-galaxy-proxy_crt.pem;
    ssl_certificate_key _ROOT_/etc/ssl/clusterware-galaxy-proxy_key.pem;
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 5m;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://galaxy_app;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-URL-SCHEME https;
    }

    # serve static content for visualization plugins
    location ~ ^/plugins/visualizations/(?<vis_name>.+?)/static/(?<static_file>.*?)$ {
        alias _ROOT_/var/lib/galaxy/config/plugins/visualizations/$vis_name/static/$static_file;
    }

    location /static {
        alias _ROOT_/opt/galaxy/galaxy/static;
        expires 24h;
    }

    location /static/style {
        alias _ROOT_/opt/galaxy/galaxy/static/june_2007_style/blue;
        expires 24h;
    }

    location /static/scripts {
        alias _ROOT_/opt/galaxy/galaxy/static/scripts/packed;
        expires 24h;
    }

    location /favicon.ico {
        alias _ROOT_/opt/galaxy/galaxy/static/favicon.ico;
        expires 24h;
    }

    location /robots.txt {
        alias _ROOT_/opt/galaxy/galaxy/static/robots.txt;
        expires 24h;
    }

    location /_x_accel_redirect/ {
        internal;
        alias /;
    }

    location /_upload {
        upload_store _ROOT_/var/lib/galaxy/database/tmp/upload_store;
        upload_pass_form_field "";
        upload_set_form_field "__${upload_field_name}__is_composite" "true";
        upload_set_form_field "__${upload_field_name}__keys" "name path";
        upload_set_form_field "${upload_field_name}_name" "$upload_file_name";
        upload_set_form_field "${upload_field_name}_path" "$upload_tmp_path";
        upload_pass_args on;
        upload_pass /_upload_done;
    }

    location /_upload_done {
        set $dst /api/tools;
        if ($args ~ nginx_redir=([^&]+)) {
            set $dst $1;
        }
        rewrite "" $dst;
    }
}
