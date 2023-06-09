#!/bin/bash

#   File di configurazione per il router vpn
#   ./setuprouter.sh <ip router> <ip honeypot> <ip VPS>


ssh root@10.10.40.140 -p 64100 "sed -i 's/10.10.40.140/$1/g' /etc/network/interfaces"
ssh root@10.10.40.140 -p 64100 "sed -i 's/10.10.40.16/$2/g' /etc/network/iptables.sh"
ssh root@10.10.40.140 -p 64100 "sed -i 's/x.x.x.x/$3/g' /etc/openvpn/client/client.conf"
ssh root@10.10.40.140 -p 64100 "systemctl enable openvpn.service"
ssh root@10.10.40.140 -p 64100 "reboot"
