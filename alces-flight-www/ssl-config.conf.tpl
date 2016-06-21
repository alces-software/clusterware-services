client_max_body_size 0;

# add Strict-Transport-Security to prevent man in the middle attacks
add_header Strict-Transport-Security "max-age=31536000";

ssl_certificate _ROOT_/etc/ssl/alces-flight-www/cert.pem;
ssl_certificate_key _ROOT_/etc/ssl/alces-flight-www/key.pem;
ssl_session_cache shared:SSL:1m;
ssl_session_timeout 5m;
ssl_ciphers HIGH:!aNULL:!MD5;
ssl_prefer_server_ciphers on;
