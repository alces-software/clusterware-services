user galaxy;
worker_processes 1;
error_log /var/log/galaxy/error.log warn;
pid /var/run/clusterware-galaxy-proxy.pid;

events {
    worker_connections 1024;
}

http {
    include _ROOT_/opt/galaxy-1510/etc/mime.types;
    default_type application/octet-stream;
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/galaxy/access.log main;
    sendfile on;
    #tcp_nopush on;
    keepalive_timeout 65;
    gzip on;
    gzip_http_version 1.1;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_proxied any;
    gzip_types text/plain text/css application/x-javascript text/xml application/xml text/javascript application/json;
    gzip_buffers 16 8k;
    gzip_disable "MSIE [1-6].(?!.*SV1)";
    include _ROOT_/opt/galaxy-1510/etc/conf.d/*.conf;
}
