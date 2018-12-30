#!/bin/bash

sudo sysctl -w net.ipv4.ip_forward=1

# http://www.revsys.com/writings/quicktips/nat.html
# http://www.karlrupp.net/en/computer/nat_tutorial
# https://killtacknine.com/building-an-ubuntu-16-04-router-part-1-network-interfaces/
out_inf="tun0" # vpn network interface

sudo iptables -F

sudo iptables -t nat -F
sudo iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o ${out_inf} -j MASQUERADE
sudo iptables -A FORWARD -s 192.168.10.0/24 -o ${out_inf} -j ACCEPT
sudo iptables -A FORWARD -d 192.168.10.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -i ${out_inf} -j ACCEPT

exit 0

cat >/etc/network/interfaces <<__EOF__
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

# WAN interface
auto eno1
iface eno1 inet dhcp

# LAN interface
auto eno4
iface eno4 inet static
  address 192.168.10.1
  network 192.168.10.0
  netmask 255.255.255.0
  broadcast 192.168.10.255
__EOF__

# sudo systemctl restart networking


# sudo apt-get install isc-dhcp-server
cat > /etc/default/dhcpd.conf <<__EOF__
# /etc/default/dhcpd.conf
INTERFACES="eno4"
__EOF__

cat >/etc/dhcp/dhcpd.conf <<__EOF__
# dhcpd.conf
#
# option definitions common to all supported networks...
option domain-name "liu.org";
option domain-name-servers 8.8.8.8, 8.8.4.4;

default-lease-time 600;
max-lease-time 7200;

# The ddns-updates-style parameter controls whether or not the server will
# attempt to do a DNS update when a lease is confirmed. We default to the
# behavior of the version 2 packages ('none', since DHCP v2 didn't
# have support for DDNS.)
ddns-update-style none;

# If this DHCP server is the official DHCP server for the local
# network, the authoritative directive should be uncommented.
authoritative;

subnet 192.168.10.0 netmask 255.255.255.0 {

    # Tells the DHCP server it can hand out IPs from the
    # range 192.168.0.100 to 192.168.0.250. If you do the
    # math, that means there are 150 (or maybe 151?, I don't
    # know if its inclusive) addresses available for clients.
    # You can make the range bigger if you have more than
    # that many clients on your LAN. Why not start at
    # 192.168.0.1? I'll get to that in the next section.
    range 192.168.10.100 192.168.10.250;

    # These two options should be the same as what your
    # configured in /etc/network/interfaces
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.168.10.255;

    # The IP address of the router clients should send their
    # traffic to. This should be the same as the static IP
    # address your configured for the router in
    # /etc/network/interfaces.
    option routers 192.168.10.1;
}
__EOF__

# sudo systemctl restart isc-dhcp-server
# sudo systemctl enable isc-dhcp-server
# sudo systemctl status isc-dhcp-server
