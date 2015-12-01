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
ServerName                      "Galaxy FTP Upload"
ServerType                      standalone
PidFile                         /var/run/clusterware-galaxy-ftpd.pid
DefaultServer                   on
Port                            21
Umask                           077
SyslogFacility                  DAEMON
SyslogLevel                     debug
MaxInstances                    30
User                            nobody
Group                           nobody
DisplayConnect                  _cw_ROOT_/var/lib/galaxy-1510/ftp_welcome.txt
UseIPv6                         off
PassivePorts                    33219 33299
DefaultRoot                     ~
CreateHome                      on dirmode 700
AllowOverwrite                  on
AllowStoreRestart               on

<Limit SITE_CHMOD>
    DenyAll
</Limit>

<Limit RETR>
    DenyAll
</Limit>

SQLEngine                       on
SQLPasswordEngine               on
SQLMinID                        361
SQLBackend                      postgres
SQLConnectInfo                  galaxy@localhost galaxy _PASSWORD_
#SQLITE#SQLBackend                      sqlite3
#SQLITE#SQLConnectInfo                  _cw_ROOT_/var/lib/galaxy-1510/database/universe.sqlite
SQLAuthenticate                 users

SQLAuthTypes                    PBKDF2
SQLPasswordPBKDF2               SHA256 10000 24
SQLPasswordEncoding             base64
SQLPasswordUserSalt             sql:/GetUserSalt
SQLUserInfo                     custom:/LookupGalaxyUser
SQLNamedQuery                   LookupGalaxyUser SELECT "email, (CASE WHEN substring(password from 1 for 6) = 'PBKDF2' THEN substring(password from 38 for 69) ELSE password END) AS password2,361,361,'_cw_ROOT_/var/lib/galaxy-1510/database/uploads/%U','/bin/bash' FROM galaxy_user WHERE email='%U'"
SQLNamedQuery                   GetUserSalt SELECT "(CASE WHEN SUBSTRING (password from 1 for 6) = 'PBKDF2' THEN SUBSTRING (password from 21 for 16) END) AS salt FROM galaxy_user WHERE email='%U'"
#SQLITE#SQLNamedQuery                   LookupGalaxyUser SELECT "email, substr(password,38,69) AS password2,361,361,'/opt/clusterware/var/lib/galaxy-1510/database/uploads/%U','/bin/bash' FROM galaxy_user WHERE email='%U'"
#SQLITE#SQLNamedQuery                   GetUserSalt SELECT "substr(password,21,16) AS salt FROM galaxy_user WHERE email='%U'"
