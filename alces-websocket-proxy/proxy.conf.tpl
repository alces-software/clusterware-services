server {
    listen 41635 ssl;
    server_name localhost;
    client_max_body_size 0;

    ssl_certificate _ROOT_/etc/ssl/alces-websocket-proxy_crt.pem;
    ssl_certificate_key _ROOT_/etc/ssl/alces-websocket-proxy_key.pem;
    ssl_session_cache shared:SSL:1m;
    ssl_session_timeout 5m;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Upgrade the connection to websockets and proxy VNC connections to a
    # remote websocket server. E.g., /192.168.24.102/12241 is proxied to
    # 192.168.24.102:12241/.
    location ~ ^/(.*)/(.*)$ {
        rewrite ^/(.*)/(.*)$ / break;
        proxy_pass http://$1:$2;
        proxy_http_version 1.1;
        proxy_set_header upgrade $http_upgrade;
        proxy_set_header connection "upgrade";
        proxy_buffering off;
        access_log /var/log/alces-websocket-proxy/websockets-access.log;
        error_log  /var/log/alces-websocket-proxy/websockets-error.log;
    }
}
