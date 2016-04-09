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

Sensitive information like external IPs, MAC addresses, SSIDs and keys in config files are masqueraded.

### Sample output of script for ethernet

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
192.168.0.6 dev wlan0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.3 dev eth0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.10 dev eth0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.1 dev wlan0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.113 dev wlan0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.3 dev wlan0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.6 dev eth0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.1 dev eth0 lladdr @@:@@:@@:@@:@@:@@ REACHABLE
192.168.0.113 dev eth0 lladdr @@:@@:@@:@@:@@:@@ REACHABLE
--- RNI016I: Check logile raspiNetInfo.log for sensitive data before publishing
[/code][/spoiler]
```

### Sample output of script for WLAN

```
pi@raspberrypi ~ $ ./raspiNetInfo.sh -s MySSID
This program comes with ABSOLUTELY NO WARRANTY; This is free software, and you are welcome to redistribute it under certain conditions
[spoiler][code]
raspiNetInfo.sh V0.2.9, $/$ - 
--- RNI010I: Starting collection of data and network analysis. This may take some time ...
--- RNI012I: Ping of 8.8.8.8 successful
??? RNI013E: Ping of www.google.com failed
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
127.0.0.1	localhost raspberrypi.@@@@@@@@@.de
127.0.1.1	owncloud
--- ip r s | egrep "(eth|wlan)"
default via 192.168.0.1 dev eth0 
192.168.0.0/24 dev eth0  proto kernel  scope link  src 192.168.0.109 
192.168.0.0/24 dev wlan0  proto kernel  scope link  src 192.168.0.118 
--- ip n s
192.168.0.6 dev wlan0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.3 dev eth0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.10 dev eth0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.1 dev wlan0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.113 dev wlan0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.3 dev wlan0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.6 dev eth0 lladdr @@:@@:@@:@@:@@:@@ STALE
192.168.0.1 dev eth0 lladdr @@:@@:@@:@@:@@:@@ REACHABLE
192.168.0.113 dev eth0 lladdr @@:@@:@@:@@:@@:@@ REACHABLE
--- lsusb | grep -v "root hub" | grep -i "wire"
Bus 001 Device 006: ID 0846:9030 NetGear, Inc. WNA1100 Wireless-N 150 [Atheros AR9271]
--- iwconfig (eth und wlan)
wlan0     IEEE 802.11bgn  ESSID:"@@@@@@@@"  
          Mode:Managed  Frequency:2.412 GHz  Access Point: @@:@@:@@:@@:@@   
          Link Quality=40/70  Signal level=-70 dBm  
          Rx invalid nwid:0  Rx invalid crypt:0  Rx invalid frag:0
          Tx excessive retries:0  Invalid misc:5308   Missed beacon:0
--- /etc/wpa_supplicant/wpa_supplicant.conf
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
	ssid="@@@@@@@@"
	psk="@@@@@@@@"
	proto=RSN
	key_mgmt=WPA-PSK
	pairwise=CCMP
	auth_alg=OPEN
}
--- grep wpa_action /var/log/messages | tail -n 15
--- RNI016I: Check logile raspiNetInfo.log for sensitive data before publishing
[/code][/spoiler]

```

## raspiSD2USB.py

Moves the root parition to an external partition and modifies /boot/cmdline.txt accordingly.
The original /boot/cmdline.txt is saved as /boot/cmdline.txt.sd just in case it's required to 
revert to use the SD card as root partition. 

### Sample output

```
raspiSD2USB.py V0.2.1 2015-04-12/20:41:05 0ff0dfd
RSD0002I --- Detected following partitions
RSD0003I --- /dev/mmcblk0p1 - Size: 112.00 MB - Free: 97.53 MB - Mountpoint: /boot - Partitionstype: vfat - Partitiontable: None
RSD0003I --- /dev/mmcblk0p2 - Size: 2.85 GB - Free: 221.95 MB - Mountpoint: / - Partitionstype: ext4 - Partitiontable: None
RSD0003I --- /dev/mmcblk0p3 - Size: 804.00 MB - Free: NA - Mountpoint: None - Partitionstype: ext4 - Partitiontable: None
RSD0003I --- /dev/sda1 - Size: 3.84 GB - Free: 3.50 GB - Mountpoint: /mnt - Partitionstype: ext4 - Partitiontable: msdos
RSD0028I --- Skipping /dev/mmcblk0p1 - Partition located on SD card
RSD0028I --- Skipping /dev/mmcblk0p2 - Partition located on SD card
RSD0028I --- Skipping /dev/mmcblk0p3 - Partition located on SD card
RSD0009I --- Target root partition candidates: /dev/sda1
RSD0011I --- Source root partition /dev/mmcblk0p2: Size: 2.85 GB Type: ext4
RSD0012I --- Testing partition /dev/sda1: Size: 3.84 GB Free space: 3.50 GB Type: ext4
RSD0005I --- Following partitions are eligible as new target root partition
RSD0006I --- /dev/sda1
RSD0007I --- Enter partion: /dev/sda1
RSD0019I --- Partition /dev/mmcblk0p2 will be copied to partition /dev/sda1 copied and become new root partition
RSD0020I --- Are you sure (y/N) ?
J
RSD0021I --- Copying rootpartition ... Please be patient
tar: Removing leading `/' from member names
tar: Write checkpoint 1000
...
tar: Write checkpoint 236000
tar: proc: implausibly old time stamp 1970-01-01 01:00:00
RSD0022I --- Updating /etc/fstab on /dev/sda1 
RSD0023I --- Saving /boot/cmdline.txt on /dev/sda1
RSD0024I --- Updating /boot/cmdline.txt on /dev/sda1
RSD0025I --- Finished moving root partition from /dev/mmcblk0p2 to partition /dev/sda1 
```
