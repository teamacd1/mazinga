#!/bin/bash

#   File di configurazione per il VPS
#   ./setupvps.sh <password>


apt update
apt upgrade -y
apt install iptables openvpn -y
systemctl enable openvpn.service

#identifica la scheda di rete
iname=$(ip -o link show | sed -rn '/^[0-9]+: e/{s/.: ([^:]*):.*/\1/p}')

#abilita il forward
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p

#genera il file iptables e lo rende eseguibile
iptable="#!/bin/bash\n\nwan=\"${iname}\"\ntun=\"tun0\"\ndst=\"10.8.134.2\"\n\n\niptables -F\niptables -F -t nat\n\niptables -t nat -A PREROUTING -p tcp -i \$wan --dport 1:64000 -j DNAT --to-destination \$dst:1-64000\niptables -t nat -A PREROUTING -p udp -i \$wan --dport 1:64000 -j DNAT --to-destination \$dst:1-64000\n\niptables -A INPUT -i lo -j ACCEPT\niptables -A INPUT -i \$tun -j ACCEPT\niptables -A INPUT -i \$wan -j ACCEPT\niptables -A INPUT -i \$wan -p udp --dport 64099 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT                       #       Porta per il tunel out tra VPS-VPSManager\niptables -A INPUT -i \$wan -m state --state RELATED,ESTABLISHED -j ACCEPT\niptables -A INPUT -m conntrack --ctstate INVALID -j DROP\niptables -A INPUT -j DROP\n\niptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT\niptables -A FORWARD -i \$tun -o \$wan -j ACCEPT\niptables -A FORWARD -i \$wan -o \$tun -j ACCEPT\niptables -A FORWARD -j DROP\n\n# Masquerade outgoing traffic\niptables -t nat -A POSTROUTING -o $wan -j MASQUERADE\n"
echo -e $iptable | tee /etc/network/iptables.sh
chmod +x /etc/network/iptables.sh

#aggiunge il post-up all'interfaccia
echo -e "   post-up /etc/network/iptables.sh" | tee -a /etc/network/interfaces

openssl enc -aes-256-cbc -d -pbkdf2 -in vps.tar.gz -out openvpn.tar.gz -pass pass:$1
tar -xzvf openvpn.tar.gz -C /etc/