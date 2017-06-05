location /customizer {
  # Don't redirect to HTTPS
}

location / {
  return 307 https://$host_HTTPS_PORT_$request_uri;
}
