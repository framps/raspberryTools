# raspberryTools
Collection of some useful tools for Raspberry Pi

1. raspiNetInfo.sh - Collect network information for people who want to help in network problem determination and test for common network configuration errors
2. raspiSD2USB.py - Transfer root partition to an external partition (e.g. USB stick, USB disk, ...) and modify /boot/cmdline.txt accordingly

## raspiNetInfo.sh

Tests executed:
1. IP assigned?
2. ping of IP in internet possible?
3. ping of hostname in internet possible?
4. default gateway defined?
5. nameserver defined in /etc/resolv.conf
6. ssid found with iwlist scan?
7. ssid conforms to IEEE 802.11?

Sensitive information like external IPs, MAC addresses and keys in config files are masqueraded.

### Sample output of script

```
pi@raspberrypi ~ $ ./raspiNetInfo.sh -e
This program comes with ABSOLUTELY NO WARRANTY; This is free software, and you are welcome to redistribute it under certain conditions
[spoiler][code]
raspiNetInfo.sh V0.2.9, $/$ - 
--- RNI010I: Starting collection of data and network analysis. This may take some time ...
--- RNI012I: Ping of 8.8.8.8 successful
--- RNI012I: Ping of www.google.com successful
--- uname -a
Linux raspberrypi 4.1.13+ #826 PREEMPT Fri Nov 13 20:13:22 GMT 2015 armv6l GNU/Linux
--- [ -d /home/pi/.xbmc ]
no
--- ip a s | egrep "(eth|wlan)
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether @@:@@:@@:@@:@@ brd @@:@@:@@:@@:@@
    inet 192.168.0.109/24 brd 192.168.0.255 scope global eth0
       valid_lft forever preferred_lft forever
       valid_lft forever preferred_lft forever
3: wlan0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
    link/ether @@:@@:@@:@@:@@ brd @@:@@:@@:@@:@@
    inet 192.168.0.118/24 brd 192.168.0.255 scope global wlan0
       valid_lft forever preferred_lft forever
       valid_lft forever preferred_lft forever
--- cat /etc/resolv | grep -i "nameserver"
nameserver 192.168.0.1
--- cat /etc/network/interfaces
auto lo
iface lo inet loopback
iface eth0 inet dhcp
allow-hotplug wlan0
iface wlan0 inet manual
wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf
iface default inet dhcp
--- cat /etc/hosts
127.0.0.1	localhost raspberrypi.@@@@@@@@@@.de
127.0.1.1	owncloud
--- ip r s | egrep "(eth|wlan)"
default via 192.168.0.1 dev eth0 
192.168.0.0/24 dev eth0  proto kernel  scope link  src 192.168.0.109 
192.168.0.0/24 dev wlan0  proto kernel  scope link  src 192.168.0.118 
--- ip n s
192.168.0.6 dev wlan0 lladdr 44:8a:5b:2b:e2:e4 STALE
192.168.0.3 dev eth0 lladdr c6:25:06:7d:97:9b STALE
192.168.0.10 dev eth0 lladdr b8:27:eb:3c:94:90 STALE
192.168.0.1 dev wlan0 lladdr 24:65:11:5c:01:a4 STALE
192.168.0.113 dev wlan0 lladdr ec:55:f9:c6:64:6c STALE
192.168.0.3 dev wlan0 lladdr c6:25:06:7d:97:9b STALE
192.168.0.6 dev eth0 lladdr 44:8a:5b:2b:e2:e4 STALE
192.168.0.1 dev eth0 lladdr 24:65:11:5c:01:a4 REACHABLE
192.168.0.113 dev eth0 lladdr ec:55:f9:c6:64:6c REACHABLE
--- RNI016I: Check logile raspiNetInfo.log for sensitive data before publishing
[/code][/spoiler]
```
