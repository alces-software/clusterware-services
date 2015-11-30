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
