#!/bin/bash

# 	 Setup a USB bootable USB device for RaspberryPi3
#	 Assumptions: Script executed on RaspberryPi booted from SD card 
#	 and the USB device only is plugged in
#
#	 See https://www.raspberrypi.org/documentation/hardware/raspberrypi/bootmodes/msd.md
#	 for details

#    Copyright (C) 2016 framp at linux-tips-and-tricks dot de
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
if [[ $UID != 0 ]]; then
	echo "Try sudo or invoce script as root"
	exit
fi

TARGET="/dev/sda"

fdisk -l $TARGET
echo "Priming $TARGET now. Are you sure? [y/N]"
read answer
answer=${answer,,}
if [[ ! $answer =~ ^[yj] ]]; then
	exit 0
fi

dd if=/dev/zero of=$TARGET bs=1MB count=10
parted $TARGET << EOF
mktable msdos 
mkpart primary fat32 0% 100M
mkpart primary ext4 100M 100%
print
quit
EOF

mkfs.vfat -n BOOT -F 32 ${TARGET}1
mkfs.ext4 ${TARGET}2

mkdir /mnt/target
mount ${TARGET}2 /mnt/target/
mkdir /mnt/target/boot
mount ${TARGET}1 /mnt/target/boot/
apt-get update; sudo apt-get install rsync
rsync -ax --progress / /boot /mnt/target

cd /mnt/target
#mount --bind /dev dev
#mount --bind /sys sys
#mount --bind /proc proc
#chroot /mnt/target << EOF 
#rm /etc/ssh/ssh_host*
#dpkg-reconfigure openssh-server
#umount dev
#umount sys
#umount proc
#EOF

sed -i "s,root=/dev/mmcblk0p2,root=${TARGET}2," /mnt/target/boot/cmdline.txt
sed -i "s,/dev/mmcblk0p,$TARGET," /mnt/target/etc/fstab

cd ~
umount /mnt/target/boot 
umount /mnt/target
#poweroff 
