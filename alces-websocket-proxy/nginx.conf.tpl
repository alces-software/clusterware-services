user nobody;
worker_processes 1;
error_log /var/log/alces-websocket-proxy/error.log warn;
pid /var/run/alces-websocket-proxy.pid;

events {
    worker_connections 1024;
}

http {
    include _ROOT_/opt/alces-websocket-proxy/etc/mime.types;
    default_type application/octet-stream;
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/alces-websocket-proxy/access.log main;
    sendfile on;
    #tcp_nopush on;
    keepalive_timeout 65;
    gzip on;
    include _ROOT_/opt/alces-websocket-proxy/etc/conf.d/*.conf;
}
