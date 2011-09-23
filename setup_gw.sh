#!/bin/sh

if [ $# -ne 1 ]; then
    exit 2;
fi

apdconf=$1

echo "Wan Interface: "
read wanInt
echo "Wifi Interface: "
read lanInt

#echo "Stopping network manager"
#/etc/init.d/NetworkManager* stop

echo "Stopping dnsmasq"
/etc/init.d/dnsmasq stop

echo "Bringing down lan interface"
#ifconfig $lanInt down
ifdown --force $lanInt

echo "Starting hostapd"
hostapd -B $apdconf
#hostapd -d -t hostapd.conf

echo "Applying configs to lan interface"
ifconfig $lanInt 10.0.0.1 netmask 255.255.255.0

echo "Staring DHCP server"
dnsmasq --no-hosts --interface $lanInt --no-poll --bind-interfaces --except-interface=lo --listen-address=10.0.0.1 --dhcp-range=10.0.0.10,10.0.0.20 --dhcp-option=option:router,10.0.0.1 --dhcp-lease-max=50 --pid-file=/var/run/nm-dnsmasq-wlan0.pid

#dnsmasq --no-hosts --interface $lanInt --no-poll --bind-interfaces --except-interface=lo --listen-address=10.0.0.1 --dhcp-range=10.0.0.10,10.0.0.20 --dhcp-option=option:router,10.0.0.254 --dhcp-lease-max=50 --pid-file=/var/run/nm-dnsmasq-wlan0.pid --dhcp-host=00:1e:52:74:40:d5,10.0.0.254,infinite --dhcp-host=60:33:4b:f4:df:c0,10.0.0.12,infinite 

echo "Stopping firewall and allowing everyone ..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT

echo "Turing on NAT"
iptables -t nat --append POSTROUTING -o $wanInt --jump MASQUERADE
#iptables -t nat -A OUTPUT -p tcp -m multiport --dports 80,443 -j DNAT --to-destination 1.1.1.1 8008

echo "Allowing ip forwarding"
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "Adding 4.2.2.1 to resolv.conf"
echo "nameserver 4.2.2.1" >> /etc/resolv.conf

