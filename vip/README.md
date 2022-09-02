### You may also need to open the firewall :
$ sudo firewall-cmd --zone=public --add-rich-rule='rule protocol value="vrrp" accept' --permanent
