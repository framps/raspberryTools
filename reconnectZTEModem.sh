#!/bin/bash

#######################################################################################################################
#
# 	  Recover from an intermittent usb device change of a ZTE GSM Modem when used with gammu
#
#	  Copy this script into /usr/local/sbin and call this script in gammu config with statement
#				runonfailure = /usr/local/sbin/reconnectZTEModem.sh		
#
#	  ZTE Modem changes usbDevice from time to time from ttyUSB2 to ttyUSB3 and vice versa. This script updates the
#	  gammu config file an restarts gammu
#
# Other gammu config settings:
# commtimeout=60
# receivefrequency=60
# resetfrequency=300
# checkbattery=0
# checksecurity=0
#
# ls -la /dev/serial/by-id/
# total 0
# drwxr-xr-x 2 root root 100 Mar 11 08:53 .
# drwxr-xr-x 4 root root  80 Mar 11 08:53 ..
# lrwxrwxrwx 1 root root  13 Mar 11 08:53 usb-ZTE_Incorporated_1_1_Surf-stick_MF19001MOD010000-if00-port0 -> ../../ttyUSB0
# lrwxrwxrwx 1 root root  13 Mar 11 08:53 usb-ZTE_Incorporated_1_1_Surf-stick_MF19001MOD010000-if01-port0 -> ../../ttyUSB1
# lrwxrwxrwx 1 root root  13 Mar 11 08:53 usb-ZTE_Incorporated_1_1_Surf-stick_MF19001MOD010000-if02-port0 -> ../../ttyUSB2 bzw ttyUSB3
#
# tail /var/log/syslog
# Mar 11 08:53:37 asterix kernel: [935267.241805] usb 1-1.2: USB disconnect, device number 19
# Mar 11 08:53:37 asterix kernel: [935267.247512] option1 ttyUSB0: GSM modem (1-port) converter now disconnected from ttyUSB0
# Mar 11 08:53:37 asterix kernel: [935267.247729] option 1-1.2:1.0: device disconnected
# Mar 11 08:53:37 asterix kernel: [935267.248888] option1 ttyUSB1: GSM modem (1-port) converter now disconnected from ttyUSB1
# Mar 11 08:53:37 asterix kernel: [935267.249076] option 1-1.2:1.1: device disconnected
# Mar 11 08:53:37 asterix kernel: [935267.252303] option1 ttyUSB3: GSM modem (1-port) converter now disconnected from ttyUSB3
# Mar 11 08:53:37 asterix kernel: [935267.252471] option 1-1.2:1.2: device disconnected
# Mar 11 08:53:42 asterix kernel: [935272.913199] usb 1-1.2: new high-speed USB device number 20 using dwc_otg
# Mar 11 08:53:43 asterix kernel: [935273.045899] usb 1-1.2: New USB device found, idVendor=19d2, idProduct=0117, bcdDevice= 0.00
# Mar 11 08:53:43 asterix kernel: [935273.045925] usb 1-1.2: New USB device strings: Mfr=3, Product=2, SerialNumber=4
# Mar 11 08:53:43 asterix kernel: [935273.045940] usb 1-1.2: Product: 1&1 Surf-stick
# Mar 11 08:53:43 asterix kernel: [935273.045951] usb 1-1.2: Manufacturer: ZTE,Incorporated
# Mar 11 08:53:43 asterix kernel: [935273.045963] usb 1-1.2: SerialNumber: MF19001MOD010000
# Mar 11 08:53:43 asterix kernel: [935273.050829] option 1-1.2:1.0: GSM modem (1-port) converter detected
# Mar 11 08:53:43 asterix kernel: [935273.051572] usb 1-1.2: GSM modem (1-port) converter now attached to ttyUSB0
# Mar 11 08:53:43 asterix kernel: [935273.052712] option 1-1.2:1.1: GSM modem (1-port) converter detected
# Mar 11 08:53:43 asterix kernel: [935273.063845] usb 1-1.2: GSM modem (1-port) converter now attached to ttyUSB1
# Mar 11 08:53:43 asterix kernel: [935273.065036] option 1-1.2:1.2: GSM modem (1-port) converter detected
# Mar 11 08:53:43 asterix kernel: [935273.065793] usb 1-1.2: GSM modem (1-port) converter now attached to ttyUSB2
# Mar 11 08:53:43 asterix kernel: [935273.066806] usb-storage 1-1.2:1.3: USB Mass Storage device detected
# Mar 11 08:53:43 asterix kernel: [935273.067697] scsi host0: usb-storage 1-1.2:1.3
#
#######################################################################################################################
#
#    Copyright (C) 2020 framp at linux-tips-and-tricks dot de
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################################################################

RETRY_CNT=3
RETRY_CNT_FILE="/var/spool/gammu/retrycnt"
RETRY_USB_FILE="/var/spool/gammu/usb"

echo "Received error parms $@"

# initialize retry counter
[[ ! -f $RETRY_CNT_FILE ]] && echo "$RETRY_CNT" > $RETRY_CNT_FILE 
r=$(<$RETRY_CNT_FILE)
# initialize usb device used 
[[ ! -f $RETRY_USB_FILE ]] && echo "" > $RETRY_USB_FILE 
u=$(<$RETRY_USB_FILE)

#usbDevice=$(tac /var/log/syslog | grep "converter now attached to" | head -n 1 | cut -f 16 -d ' ')
usbDevice=$(ls -la /dev/serial/by-id/ | tail -n 1 | cut -f 12 -d ' ' | sed 's/[\./]//g')

# usb device flipped, initialize retry count
[[ $usbDevice != $u ]] && r=$RETRY_CNT

echo "r: $r u: $u usbDevice: $usbDevice" 

# stop gammu because of too many retries
if (( $r == 0 )); then
	echo "Stopping retry"
	rm $RETRY_CNT_FILE 
	service gammu-smsd stop
	exit
fi

# update usb device (port) in gammu config
sed -E -i "s%^port.+$%port = /dev/$usbDevice%" /etc/gammu-smsdrc

# report retry in gammu log
c=$(( $RETRY_CNT + 1 - $r ))
echo "Retry $c with $usbDevice"

# restart gammu to use the new device
service gammu-smsd restart

# update retry count and usb device used
if [[ $usbDevice == $u ]]; then
	echo $(( $r - 1 )) > $RETRY_CNT_FILE
	echo "Decremented retry count for $u to $(<$RETRY_CNT_FILE)"
else
	echo "Clear retry count for $usbDevice"	
	echo $usbDevice > $RETRY_USB_FILE
	rm $RETRY_CNT_FILE
fi      	
