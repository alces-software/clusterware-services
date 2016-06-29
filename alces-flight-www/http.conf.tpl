server {
  listen _HTTP_PORT_ default;
  include _ROOT_/etc/alces-flight-www/server-http.d/*.conf;
}
