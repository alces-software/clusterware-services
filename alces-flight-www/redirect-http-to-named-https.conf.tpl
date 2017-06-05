server_name _SERVER_NAME_;

location /customizer {
  # Don't redirect to HTTPS
}

location / {
  return 307 https://$server_name_HTTPS_PORT_$request_uri;
}
