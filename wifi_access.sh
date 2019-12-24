#!/bin/bash
#change ip_address, ssid, dhcp-range, and wpa_passphrase to your liking

apt install dnsmasq hostapd
systemctl stop dnsmasq
systemctl stop hostapd

#backup files
cp /etc/dhcpcd.conf /etc/dhcpd.conf.bak
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak

#set IP of pi
cat >>/etc/dhcpcd.conf <<EOL
interface wlan0
  static ip_address=192.168.6.1/24
  nohook wpa_supplicant
EOL

service dhcpcd restart
touch /etc/dnsmasq.conf
  
cat >>/etc/dnsmasq.conf <<EOL
interface=wlan0      # Use the require wireless interface - usually wlan0
dhcp-range=192.168.6.2,192.168.6.20,255.255.255.0,24h
EOL

systemctl reload dnsmasq

touch /etc/hostapd/hostapd.conf
cat >>/etc/hostapd/hostapd.conf <<EOL
interface=wlan0
driver=nl80211
ssid=CHANGEME
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=CHANGEME
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOL

cat >>/etc/default/hostapd.conf <<EOL
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOL

systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd

cat >>/etc/sysctl.conf <<EOL
net.ipv4.ip_forward=1
EOL

iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
sh -c "iptables-save > /etc/iptables.ipv4.nat"
iptables-restore < /etc/iptables.ipv4.nat
