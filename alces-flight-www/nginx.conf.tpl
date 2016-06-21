user nobody;
worker_processes 1;
error_log /var/log/alces-flight-www/error.log warn;
pid /var/run/alces-flight-www.pid;

events {
    worker_connections 1024;
}

http {
    include _ROOT_/opt/alces-flight-www/etc/mime.types;
    default_type application/octet-stream;
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/alces-flight-www/access.log main;
    sendfile on;
    #tcp_nopush on;
    keepalive_timeout 65;
    gzip on;
    include _ROOT_/etc/alces-flight-www/http.d/*.conf;
}
