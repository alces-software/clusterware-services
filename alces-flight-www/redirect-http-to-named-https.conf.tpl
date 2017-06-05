server_name _SERVER_NAME_;

if ($is_prv_addr = 0) {
  return 307 https://$server_name_HTTPS_PORT_$request_uri;
}
