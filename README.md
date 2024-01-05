![](https://img.shields.io/github/last-commit/framps/raspberryTools.svg?style=flat)

## Note:
There is a [very useful tools collection](https://forums.raspberrypi.com/viewtopic.php?t=196778) available, called usb-tools **Running Raspbian from USB Devices : Made Easy** which contains four very nice tools called usb-boot, sdc-boot, mbr2gpt and set-partuuid.

# raspberryTools
Collection of some useful tools for Raspberry Pi. For sample outputs of the tools click the links.

1. [raspiNetInfo.sh](#raspinetinfosh) - Collect network information for people who want to help in network problem determination and test for common network configuration errors

2. checkWLANAndRestart.sh - Check on regular base for WLAN connection and either restart network interface or reboot Raspberry if there is no connection

3. [checkThrottled.sh](#checkthrottledsh) - Check Raspberry throttled bits with `vcgencmd get_throttled` and display their meaning if throtteling happened since boot or since last script invocation

4. [testCPUTemperature.sh](#testcputemperaturesh) - Generates 100% CPU load on a Raspberry and monitors the CPU temperature. Useful to test the effectiveness of a heat sink and/or fan.

5. [retrieveTerrabytesWritten.sh](#retrieveterrabyteswrittensh) - Either retrieves the Total Bytes Written of all existing SSDs on the system or a specific SSD. Helps to get an idea when the SSD will reach it's end of life.

6. [retrieveLifetimeWrites.sh](#retrievelifetimewritessh) - Either retrieves the LifetimeWrites of one or all existing ext2/ext3 and ext4 partitions. Helps to get an idea when the SD card or disk will reach it's end of life.

7. [findRaspis.sh](#findraspissh) - Scan the local net for Raspberries and print the IPs, macs and hostnames sorted by IP. A config file can be used to add an additional descriptions for the hostname

8. [smsRelay.py](#smsrelaypy) - Receives all SMS and forwards them to an eMail. UMTS stick and python2 required. Depends on Python2 and therefore is outdated. Use smstools and eventhandler file smsevent instead.

9. [checkPARTUUIDsInDDImage.sh](https://github.com/framps/raspberryTools/blob/master/checkPARTUUIDsInDDImage.sh) - Retrieve PARTUUIDs of Raspberry dd Backup image partitions /boot and / and check if they match in /boot/cmdline.txt and /etc/fstab

10. [syncUUIDs.sh](https://github.com/framps/raspberryTools/blob/master/syncUUIDs.sh) - Check whether /boot/cmdline.txt and /etc/fstab on a device match the UUIDs or PARTUUIDs used on the device partitions. Option -u will synchronize the files. Useful when an image was cloned to another device and fails during boot.

11. [raspiKernelInfo.sh](https://github.com/framps/raspberryTools/blob/master/raspiKernelInfo.sh) - Retrieve info about the running system on a Raspberry

12. [raspiHandleKernels.sh](https://github.com/framps/raspberryTools/blob/master/raspiHandleKernels.sh) - Delete and reinstall unused kernels in a bookworm image to speed up apt upgrade processing

## findRaspis.sh

```
findRaspis.sh
Scanning subnet 192.168.0.0/24 for Raspberries ...

IP address      Mac address       Hostname (Description)
192.168.0.8     b8:27:eb:b4:e8:74 troubadix (Networking server)
192.168.0.10    b8:27:eb:3c:94:90 idefix (Homeautomation server)
192.168.0.12    dc:a6:32:8f:28:fd asterix (LAN server)
```

## syncUUIDs.sh

Check UUIDs (UUIDs are OK):
```
sudo ./syncUUIDs.sh  /dev/mmcblk0
/dev/mmcblk0p1 has PARTUUID 5e1ad0e3-01
/dev/mmcblk0p2 has PARTUUID 5e1ad0e3-02
Boot PARTUUID 5e1ad0e3-01 already used in /etc/fstab
Root PARTUUID 5e1ad0e3-02 already used in /etc/fstab and /cmdline.txt
```

Check UUIDs (UUIDs are not OK):

```
sudo ./syncUUIDs.sh  /dev/mmcblk0
/dev/mmcblk0p1 has PARTUUID 5e1ad0e3-01
/dev/mmcblk0p2 has PARTUUID 5e1ad0e3-02
PARTUUID 1e1ad0e3-01 should be updated to 5e1ad0e3-01 in /etc/fstab on /dev/mmcblk0p2
PARTUUID 1e1ad0e3-02 should be updated to 5e1ad0e3-02 in /etc/fstab on /dev/mmcblk0p2
PARTUUID 1e1ad0e3-02 should be updated to 5e1ad0e3-02 in /cmdline.txt on /dev/mmcblk0p1
```

Update UUIDs (UUIDs are not OK):

```
sudo ./syncUUIDs.sh  -u /dev/mmcblk0
/dev/mmcblk0p1 has PARTUUID 5e1ad0e3-01
/dev/mmcblk0p2 has PARTUUID 5e1ad0e3-02
Creating fstab backup /etc/fstab.bak on /dev/mmcblk0p2
Updating PARTUUID 1e1ad0e3-01 to 5e1ad0e3-01 in /etc/fstab on /dev/mmcblk0p2
Updating PARTUUID 1e1ad0e3-02 to 5e1ad0e3-02 in /etc/fstab on /dev/mmcblk0p2
Creating cmdline backup /cmdline.txt.bak on /dev/mmcblk0p1
Updating PARTUUID 1e1ad0e3-02 to 5e1ad0e3-02 in cmdline.txt on /dev/mmcblk0p1
```

## checkThrottled.sh

[Code](https://github.com/framps/raspberryTools/blob/master/checkThrottled.sh)

```
pi@raspberrypi-buster:~ $ ./checkThrottled.sh
Throttling in hex (bits reset on boot): 0x20000
Bit 17 set: Arm frequency capped has occurred
Throttling in hex: 0x20002 (bits reset every call)
```

## testCPUTemperature.sh

[Code](https://github.com/framps/raspberryTools/blob/master/testCPUTemperature.sh)

```
pi@raspberrypi-buster:~ $ ./testCPUTemperature.sh -i 5
Generate 100% CPU utilization and measure CPU temperature ...
CPU watch interval: 5s
Watch +0s:temp=55.8'C
Starting run 1: +0s:temp=56.4'C
Watch +5s:temp=64.5'C
Watch +10s:temp=67.7'C
Watch +15s:temp=70.4'C
Watch +20s:temp=73.1'C
Watch +25s:temp=74.1'C
Watch +30s:temp=76.3'C
Watch +35s:temp=77.4'C
Watch +40s:temp=79.0'C
Watch +45s:temp=80.6'C
Watch +50s:temp=80.6'C
Watch +55s:temp=81.1'C
Watch +60s:temp=81.7'C
Watch +65s:temp=82.2'C
Watch +70s:temp=82.7'C
Watch +75s:temp=82.7'C
```

## retrieveLifetimeWrites.sh

[Code](https://github.com/framps/raspberryTools/blob/master/retrieveLifetimeWrites.sh)

```
sudo retrieveLifetimeWrites.sh  -a
LTW of /dev/mmcblk0p2: 57.35 GiB
LTW of /dev/sdd1: 1.66 TiB
LTW of /dev/md0: 596.31 GiB
```

## retrieveTerrabytesWritten.sh

[Code](https://github.com/framps/raspberryTools/blob/master/retrieveTerrabytesWritten.sh)
```
sudo retrieveTBW.sh -a
TBW of sda: 1.56 TiB
```

## smsRelay.py

Sample eMail relayed for a `*ping` SMS

```
Dear SMSRelayUser

I just received following SMS from +4947114712 for +4947144715 which I forward to you:

--- START SMS ---
*ping
---  END SMS  ---

Hope you enjoy my service.

Regards

Your SMS relay server on smsrelay.dummy.com
```

## raspiNetInfo.sh

[Code](https://github.com/framps/raspberryTools/blob/master/raspiNetInfo.sh)

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
