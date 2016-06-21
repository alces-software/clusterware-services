server {
  listen _HTTP_PORT_ default;
  include _ROOT_/etc/alces-flight-www/server-http.d/*.conf;
}

server {
  listen _HTTPS_PORT_ ssl default;
  include _ROOT_/etc/alces-flight-www/server-https.d/*.conf;
}
