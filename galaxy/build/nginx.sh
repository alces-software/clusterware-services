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
curl -L "http://nginx.org/download/nginx-1.6.2.tar.gz" -o /tmp/nginx.tar.gz
curl -L "https://github.com/vkholodkov/nginx-upload-module/archive/2.2.zip" -o /tmp/nginx_upload_module.zip

tar -C /tmp -xzf /tmp/nginx.tar.gz
unzip -d /tmp /tmp/nginx_upload_module.zip >/dev/null
pushd /tmp/nginx-1.6.2

NGINXDIR="${SERVICEDIR}"
./configure \
    --prefix=$NGINXDIR/etc/nginx \
    --conf-path=$NGINXDIR/etc/nginx.conf \
    --sbin-path=$NGINXDIR/bin/nginx \
    --pid-path=/var/run/clusterware-galaxy-proxy.pid \
    --lock-path=/var/run/lock/clusterware-galaxy-proxy.lock \
    --user=nobody \
    --group=nobody \
    --http-log-path=/var/log/galaxy/access.log \
    --error-log-path=stderr \
    --http-client-body-temp-path=$NGINXDIR/var/lib/client-body \
    --http-proxy-temp-path=$NGINXDIR/var/lib/proxy \
    --http-fastcgi-temp-path=$NGINXDIR/var/lib/fastcgi \
    --http-scgi-temp-path=$NGINXDIR/var/lib/scgi \
    --http-uwsgi-temp-path=$NGINXDIR/var/lib/uwsgi \
    --with-imap \
    --with-imap_ssl_module \
    --with-ipv6 \
    --with-pcre-jit \
    --with-file-aio \
    --with-http_dav_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_realip_module \
    --with-http_spdy_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_addition_module \
    --with-http_degradation_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_secure_link_module \
    --with-http_sub_module \
    --add-module=/tmp/nginx-upload-module-2.2
make
make install

rm "$NGINXDIR"/etc/*.default
install -dm700 "$NGINXDIR"/etc/conf.d
install -d "$NGINXDIR"/man/man8/
gzip -9c man/nginx.8 > "$NGINXDIR"/man/man8/nginx.8.gz
install -d "$NGINXDIR"/var/lib
install -dm700 "$NGINXDIR"/var/lib/proxy

popd
install -Dm644 build/nginx.conf.tpl "$NGINXDIR"/etc/nginx.conf
install -Dm644 build/galaxy.conf.tpl "$NGINXDIR"/etc/conf.d/galaxy.conf
sed -e "s,_ROOT_,${cw_ROOT},g" -i "$NGINXDIR"/etc/nginx.conf "$NGINXDIR"/etc/conf.d/galaxy.conf

rm -rf /tmp/nginx_upload_module.zip /tmp/nginx.tar.gz /tmp/nginx-1.6.2 /tmp/nginx-upload-module-2.2
