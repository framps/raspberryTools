![](https://img.shields.io/github/last-commit/framps/raspberryTools.svg?style=flat)
![](https://img.shields.io/github/stars/framps/raspberryTools?style=flat)

***
If you like my work and want me to be able to keep improving it, please sponsor me on [GitHub](https://github.com/sponsors/framps) or visit [this page](https://www.linux-tips-and-tricks.de/en/donations) which lists alternate ways to donate.
***

### Note
There is a [very useful tools collection](https://forums.raspberrypi.com/viewtopic.php?t=196778) available, called usb-tools **Running Raspbian from USB Devices : Made Easy** which contains four very nice tools called usb-boot, sdc-boot, mbr2gpt and set-partuuid.

### Note
Use invokeTool.sh to download and call a tool immediately.

Examples:
*   `curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/invokeTool.sh | bash -s -- findSensors.sh -s m`
*   `curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/invokeTool.sh | sudo bash -s -- synUUIDs.sh -u /dev/mmcblk0`

Or use downloadRepoFiles.sh to select multiple tools you want to download and test first. Optionally you can install them later with option `-i`.

Command to download and execute downloadRepoFiles.sh:
* `curl -s -O https://raw.githubusercontent.com/framps/raspberryTools/master/downloadRepoFiles.sh; bash ./downloadRepoFiles.sh -i`

### List of my "some useful tools for Raspberry Pi"
For sample outputs of the tools click the links.

1. [raspiNetInfo.sh](#raspinetinfosh) - Collect network information for people who want to help in network problem determination and test for common network configuration errors

2. checkWLANAndRestart.sh - Check on regular base for WLAN connection and either restart network interface or reboot Raspberry if there is no connection

3. [checkThrottled.sh](#checkthrottledsh) - Check Raspberry throttled bits with `vcgencmd get_throttled` and display their meaning if throtteling happened since boot or since last script invocation

4. [testCPUTemperature.sh](#testcputemperaturesh) - Generates 100% CPU load on a Raspberry and monitors the CPU temperature. Useful to test the effectiveness of a heat sink and/or fan.

5. [retrieveTerrabytesWritten.sh](#retrieveterrabyteswrittensh) - Either retrieves the Total Bytes Written of all existing SSDs on the system or a specific SSD. Helps to get an idea when the SSD will reach it's end of life.

6. [retrieveLifetimeWrites.sh](#retrievelifetimewritessh) - Either retrieves the LifetimeWrites of one or all existing ext2/ext3 and ext4 partitions. Helps to get an idea when the SD card or disk will reach it's end of life.

7. [findDevices.sh](#finddevicessh) - Scan the local net for Raspberries or ESPs and print the IPs, macs and hostnames sorted by IP. A config file can be used to add an additional descriptions for the hostname. This replaces deprecated findRaspis and findSensors.

8. findRaspis.sh - Deprecated. Use findDevices.sh

9. findSensors.sh - Deprecated. Use findDevices.sh

10. [checkPARTUUIDsInDDImage.sh](https://github.com/framps/raspberryTools/blob/master/checkPARTUUIDsInDDImage.sh) - Retrieve PARTUUIDs of Raspberry dd Backup image partitions /boot and / and check if they match in /boot/cmdline.txt and /etc/fstab

11. [syncUUIDs.sh](https://github.com/framps/raspberryTools/blob/master/syncUUIDs.sh) - Check whether /boot/cmdline.txt and /etc/fstab on a device match the UUIDs, PARTUUIDs or LABELs used on the device partitions. Option -u (update) will synchronize the files. Useful when an image was cloned to another device and fails during boot because of missing updates in /boot/cmdline.txt and /etc/fstab.
With option -n (new) new UUIDs and PARTUUIDs are created on the target device and /boot/cmdline.txt and /etc/fstab are updated accordingly. Useful if somebody uses dd to clone a system and requires to have the clone mounted on the cloned system **Note**: Runs on any Linux OS and HW

12. [raspiKernelInfo.sh](https://github.com/framps/raspberryTools/blob/master/raspiKernelInfo.sh) - Retrieve info about the running system on a Raspberry

13. [raspiHandleKernels.sh](#raspiHandleKernels.sh) - Uninstall and reinstall unused kernels in a bookworm image to speed up apt upgrade processing

14. [switchOS.sh](https://github.com/framps/raspberryTools/blob/master/switchOS.sh) - Switch the OS boot device if there are multiple boot devices (e.g. mmcblk0 and nvme0n1)


## findDevices.sh
```
findDevices.sh 0.1.0 (https://github.com/framps/raspberryTools)
Scanning subnet 192.168.0.0/24 for Raspberries ...

IP address      Mac address       Hostname                                        Description
192.168.0.8     b8:27:eb:a4:e8:74 troubadix                                       NetworkGateway
192.168.0.10    b8:27:eb:2c:94:90 idefix                                          HomeAutomation
192.168.0.12    dc:a6:32:7f:28:fd asterix                                         InfluxDB/Grafana
192.168.0.158   dc:a6:32:ef:4f:9a raspberrypi-bookworm-64-lite-cm4-emmc.fritz.box CM4
192.168.0.164   dc:a6:32:bb:d9:7e raspberrypi4-8GB.fritz.box                      RPi4
192.168.0.179   2c:cf:67:b2:18:90 raspberrypi-bookworm64-lite-beta.fritz.box      RPi5
```

## raspiHandleKernels.sh

Display unused kernels
```
raspiHandleKernels.sh v0.2.4 (https://github.com/framps/raspberryTools)
--- Following kernel is used
linux-image-6.6.31+rpt-rpi-v8
--- Following 3 kernels are not required and can be uninstalled to speed up system updates
--- Note the kernel names are saved in /boot/raspiHandleKernels.krnl and thus can be reinstalled if hardware changes
linux-image-6.6.31+rpt-rpi-2712
linux-image-rpi-2712
linux-image-rpi-v8
--- Use option -e to uninstall 3 unused kernels
```

Uninstall unused kernels
```
./raspiHandleKernels.sh -e
raspiHandleKernels.sh v0.2.4 (https://github.com/framps/raspberryTools)
--- Following kernel is used
linux-image-6.6.31+rpt-rpi-v8
--- Following 3 kernels are not required and can be uninstalled to speed up system updates
--- Note the kernel names are saved in /boot/raspiHandleKernels.krnl and thus can be reinstalled if hardware changes
linux-image-6.6.31+rpt-rpi-2712
linux-image-rpi-2712
linux-image-rpi-v8
--- Are you sure to uninstall all 3 unused kernels ? (y/N) y
--- Do you have a backup ? (y/N) y
--- Saving 3 unused kernel names in /boot/raspiHandleKernels.krnl
--- Removing 3 unused kernels
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  linux-image-6.6.31+rpt-rpi-2712 linux-image-rpi-2712 linux-image-rpi-v8
0 upgraded, 0 newly installed, 3 to remove and 1 not upgraded.
After this operation, 33.0 MB disk space will be freed.
(Reading database ... 55838 files and directories currently installed.)
Removing linux-image-rpi-2712 (1:6.6.31-1+rpt1) ...
Removing linux-image-6.6.31+rpt-rpi-2712 (1:6.6.31-1+rpt1) ...
/etc/kernel/postrm.d/initramfs-tools:
update-initramfs: Deleting /boot/initrd.img-6.6.31+rpt-rpi-2712
/etc/kernel/postrm.d/z50-raspi-firmware:
removed '/boot/firmware/kernel_2712.img'
removed '/boot/firmware/initramfs_2712'
Removing linux-image-rpi-v8 (1:6.6.31-1+rpt1) ...

```

Display kernels which will be reinstalled
```
./raspiHandleKernels.sh
raspiHandleKernels.sh v0.2.4 (https://github.com/framps/raspberryTools)
--- Following 3 unused kernels can be reinstalled
linux-image-6.6.31+rpt-rpi-2712
linux-image-rpi-2712
linux-image-rpi-v8
--- Use option -e to reinstall 3 unused kernels
```

Reinstall unused kernels
```
./raspiHandleKernels.sh -e
raspiHandleKernels.sh v0.2.4 (https://github.com/framps/raspberryTools)
--- Following 3 unused kernels can be reinstalled
linux-image-6.6.31+rpt-rpi-2712
linux-image-rpi-2712
linux-image-rpi-v8
--- Are you sure to reinstall all 3 unused kernels ? (y/N) y
--- Installing 3 unused kernels
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
ySuggested packages:
  linux-doc-6.6 debian-kernel-handbook
The following NEW packages will be installed:
  linux-image-6.6.31+rpt-rpi-2712
0 upgraded, 1 newly installed, 0 to remove and 1 not upgraded.
Need to get 29.4 MB of archives.
After this operation, 32.9 MB of additional disk space will be used.
Get:1 http://archive.raspberrypi.com/debian bookworm/main arm64 linux-image-6.6.31+rpt-rpi-2712 arm64 1:6.6.31-1+rpt1 [29.4 MB]
Fetched 29.4 MB in 3s (10.5 MB/s)
Selecting previously unselected package linux-image-6.6.31+rpt-rpi-2712.
(Reading database ... 53260 files and directories currently installed.)
Preparing to unpack .../linux-image-6.6.31+rpt-rpi-2712_1%3a6.6.31-1+rpt1_arm64.deb ...
Unpacking linux-image-6.6.31+rpt-rpi-2712 (1:6.6.31-1+rpt1) ...
Setting up linux-image-6.6.31+rpt-rpi-2712 (1:6.6.31-1+rpt1) ...
/etc/kernel/postinst.d/initramfs-tools:
update-initramfs: Generating /boot/initrd.img-6.6.31+rpt-rpi-2712
'/boot/initrd.img-6.6.31+rpt-rpi-2712' -> '/boot/firmware/initramfs_2712'
/etc/kernel/postinst.d/z50-raspi-firmware:
'/boot/vmlinuz-6.6.31+rpt-rpi-2712' -> '/boot/firmware/kernel_2712.img'
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  linux-image-rpi-2712
0 upgraded, 1 newly installed, 0 to remove and 1 not upgraded.
Need to get 1,432 B of archives.
After this operation, 13.3 kB of additional disk space will be used.
Get:1 http://archive.raspberrypi.com/debian bookworm/main arm64 linux-image-rpi-2712 arm64 1:6.6.31-1+rpt1 [1,432 B]
Fetched 1,432 B in 0s (8,335 B/s)
Selecting previously unselected package linux-image-rpi-2712.
(Reading database ... 55832 files and directories currently installed.)
Preparing to unpack .../linux-image-rpi-2712_1%3a6.6.31-1+rpt1_arm64.deb ...
Unpacking linux-image-rpi-2712 (1:6.6.31-1+rpt1) ...
Setting up linux-image-rpi-2712 (1:6.6.31-1+rpt1) ...
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  linux-image-rpi-v8
0 upgraded, 1 newly installed, 0 to remove and 1 not upgraded.
Need to get 1,428 B of archives.
After this operation, 13.3 kB of additional disk space will be used.
Get:1 http://archive.raspberrypi.com/debian bookworm/main arm64 linux-image-rpi-v8 arm64 1:6.6.31-1+rpt1 [1,428 B]
Fetched 1,428 B in 0s (8,847 B/s)
Selecting previously unselected package linux-image-rpi-v8.
(Reading database ... 55835 files and directories currently installed.)
Preparing to unpack .../linux-image-rpi-v8_1%3a6.6.31-1+rpt1_arm64.deb ...
Unpacking linux-image-rpi-v8 (1:6.6.31-1+rpt1) ...
Setting up linux-image-rpi-v8 (1:6.6.31-1+rpt1) ...
```


## syncUUIDs.sh

Check UUIDs (UUIDs are OK):
```
sudo syncUUIDs.sh  /dev/mmcblk0
--- Root PARTUUID 18aea473-02 already used in /dev/mmcblk0p1/cmdline.txt
--- Boot PARTUUID 18aea473-01 already used in /dev/mmcblk0p2/etc/fstab
--- Root PARTUUID 18aea473-02 already used in /dev/mmcblk0p2/etc/fstab
```

Check UUIDs (UUIDs are not OK) (Note: There is a mix of UUID and PARTUUID usage):

```
sudo syncUUIDs.sh /dev/mmcblk0
!!! PARTUUID 1aea473-02 should be updated to 18aea473-02 in /dev/mmcblk0p1/cmdline.txt
!!! UUID 18aea473-01 should be updated to 5DF9-E225 in /dev/mmcblk0p2/etc/fstab
!!! PARTUUID 18aea47-02 should be updated to 18aea473-02 in /dev/mmcblk0p2/etc/fstab
!!! Use option -u to update the incorrect UUIDs or PARTUUIDs
```

Update UUIDs (UUIDs are not OK):

```
sudo syncUUIDs.sh  -u /dev/mmcblk0
--- Creating cmdline backup cmdline.txt.bak on /dev/mmcblk0p1
--- Updating PARTUUID 1aea473-02 to 18aea473-02 in /dev/mmcblk0p1/cmdline.txt
--- Creating fstab backup etc/fstab.bak on /dev/mmcblk0p2
--- Updating UUID 18aea473-01 to 5DF9-E225 in /dev/mmcblk0p2/etc/fstab
--- Updating PARTUUID 18aea47-02 to 18aea473-02 in /dev/mmcblk0p2/etc/fstab
```

Check if update was successfull :
```
sudo syncUUIDs.sh /dev/mmcblk0
--- Root PARTUUID 18aea473-02 already used in /dev/mmcblk0p1/cmdline.txt
--- Boot UUID 5DF9-E225 already used in /dev/mmcblk0p2/etc/fstab
--- Root PARTUUID 18aea473-02 already used in /dev/mmcblk0p2/etc/fstab
```

Use PARTUUID in fstab now:
```
sudo syncUUIDs.sh -u /dev/mmcblk0
--- Root PARTUUID 18aea473-02 already used in /dev/mmcblk0p1/cmdline.txt
--- Creating fstab backup etc/fstab.bak on /dev/mmcblk0p2
--- Updating PARTUUID 5DF9-E225 to 18aea473-01 in /dev/mmcblk0p2/etc/fstab
--- Root PARTUUID 18aea473-02 already used in /dev/mmcblk0p2/etc/fstab
sudo syncUUIDs.sh /dev/mmcblk0
--- Root PARTUUID 18aea473-02 already used in /dev/mmcblk0p1/cmdline.txt
--- Boot PARTUUID 18aea473-01 already used in /dev/mmcblk0p2/etc/fstab
--- Root PARTUUID 18aea473-02 already used in /dev/mmcblk0p2/etc/fstab
```

Generate new UUIDs and PARTUUIDs
```
sudo syncUUIDs.sh -n /dev/sda
syncUUIDs.sh 0.3 (https://github.com/framps/raspberryTools)
!!! Creating new UUID and PARTUUID on /dev/sda. Are you sure? (y|N) y
--- Creating new PARTUUID 856f0aa3 on /dev/sda
--- Creating new UUID D0D0-1BF8 on /dev/sda1
4+0 records in
4+0 records out
4 bytes copied, 0.0035762 s, 1.1 kB/s
--- Creating new UUID f685cb4a-b320-4d81-8dd4-a7e0943e0b7c on /dev/sda2
e2fsck 1.47.0 (5-Feb-2023)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/sda2: 61814/452480 files (0.1% non-contiguous), 505485/1808384 blocks
tune2fs 1.47.0 (5-Feb-2023)
Setting the UUID on this filesystem could take some time.
Proceed anyway (or wait 5 seconds to proceed) ? (y,N) <proceeding>
!!! PARTUUID cc5fd38e-02 should be updated to 856f0aa3-02 in /dev/sda1/cmdline.txt
!!! PARTUUID cc5fd38e-01 should be updated to 856f0aa3-01 in /dev/sda2/etc/fstab
!!! PARTUUID cc5fd38e-02 should be updated to 856f0aa3-02 in /dev/sda2/etc/fstab
!!! Use option -u to update the incorrect UUIDs, PARTUUIDs or LABELs
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
