#!/bin/bash
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
sed -e "s,_cw_ROOT_,${cw_ROOT},g" -i "$SERVICEDIR"/etc/proftpd.conf
