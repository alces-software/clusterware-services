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
curl -L "ftp://ftp.proftpd.org/distrib/source/proftpd-1.3.5a.tar.gz" -o /tmp/proftpd-1.3.5a.tar.gz
tar -C /tmp -xzf /tmp/proftpd-1.3.5a.tar.gz
pushd /tmp/proftpd-1.3.5a
./configure --prefix="${SERVICEDIR}" \
    --disable-auth-file --disable-ncurses --disable-ident \
    --disable-shadow --enable-openssl --with-modules=mod_sql:mod_sql_postgres:mod_sql_passwd:mod_sql_sqlite
make
make install
popd
install -Dm640 build/proftpd.conf.tpl "$SERVICEDIR"/etc/proftpd.conf

rm -rf /tmp/proftpd-1.3.5a.tar.gz /tmp/proftpd-1.3.5a
