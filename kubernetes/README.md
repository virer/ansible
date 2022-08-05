Work in progress

TODO:
>Add dnsmasq, haproxy and keepalived

PROXY fix:
> cat <<EOF>>/etc/sysconfig/crio
  HTTPS_PROXY=http://webproxy.example.be:8080
  HTTP_PROXY=http://webproxy.example.be:8080
  http_proxy=http://webproxy.example.be:8080
  https_proxy=http://webproxy.example.be:8080
  NO_PROXY=.example.be
  no_proxy=.example.be
  EOF

  # systemctl restart crio
