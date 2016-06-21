# Upgrade the connection to websockets and proxy VNC connections to a
# remote websocket server. E.g., /ws/192.168.24.102/12241 is proxied to
# 192.168.24.102:12241/.
location ~ ^/ws/(.*)/(.*)$ {
    proxy_connect_timeout 7d;
    proxy_send_timeout 7d;
    proxy_read_timeout 7d;
    rewrite ^/ws/(.*)/(.*)$ / break;
    proxy_pass http://$1:$2;
    proxy_http_version 1.1;
    proxy_set_header upgrade $http_upgrade;
    proxy_set_header connection "upgrade";
    proxy_buffering off;
    access_log /var/log/alces-flight-www/websockets-access.log;
    error_log  /var/log/alces-flight-www/websockets-error.log;
}
