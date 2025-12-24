uci set network.wan.proto='static'
uci set network.wan.ipaddr='192.168.1.29'  # 您的IP
uci set network.wan.netmask='255.255.255.0'
uci set network.wan.gateway='192.168.1.27'   # 上级路由器IP
uci set network.wan.dns='8.8.8.8 1.1.1.1'
uci commit network
/etc/init.d/network restart