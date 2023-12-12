#!/bin/bash

#######################################################################################################################
#
# 	 This script deletes unused kernels on a Raspberry Pi running bookworm with option -u and
#	 creates a file /boot/deletedKernels.txt in order to be able to reinstall the deleted kernels with option -i
#
#	 Use option -e to actually execute the updates on the system. Otherwise it's just a dry run.
#
#######################################################################################################################
#
#    Copyright (c) 2023 framp at linux-tips-and-tricks dot de
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

set -eo pipefail

readonly MYSELF="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
readonly MYNAME=${MYSELF%.*}
readonly DELETED_KERNELS_FILENAME="deletedKernels.txt"

function show_help() {
	echo "$MYSELF -i (-e)? | -u (-e)? | -h "
	echo "-e: deactivate dry run mode and modify system"
	echo "-i: reinstall kernels deleted with option -u"
	echo "-u: uninstall any unused kernels"
	echo "-h: display this help"
}

function do_uninstall() {
	if (( ! $MODE_EXECUTE )); then
		echo "Following kernels will be deleted"
		ls -1 /boot | grep -v -E $(uname -r) | grep -E "^initrd" | sed 's/initrd/linux-image/; s/\.img//' | xargs -I {} echo "sudo apt remove {}" 
	else
		echo -n "Are you sure to delete all unused kernels (y/N) ? "
		read answer
		answer=${answer:0:1}
		answer=${answer:-"n"}

		if [[ ! "Yy" =~ $answer ]]; then
			exit 1
		fi

		echo -n "Do you have a backup (y/N) ? "
		read answer
		answer=${answer:0:1}
		answer=${answer:-"n"}

		if [[ ! "Yy" =~ $answer ]]; then
			exit 1
		fi

		sudo rm /boot/$DELETED_KERNELS_FILENAME
		(( $? )) && { echo "Failure deleting /boot/$DELETED_KERNELS_FILENAME"; exit 42; }
		ls -1 /boot | grep -v -E $(uname -r) | grep -E "^initrd" | sed 's/initrd/linux-image/; s/\.img//' | xargs -I {} echo -e "{}" >> $DELETED_KERNELS_FILENAME; sudo mv $DELETED_KERNELS_FILENAME /boot
		(( $? )) && { echo "Failure collect kernels"; exit 42; }
		ls -1 /boot | grep -v -E $(uname -r) | grep -E "^initrd" | sed 's/initrd/linux-image/; s/\.img//' | xargs sudo apt -y remove		
		(( $? )) && { echo "Failure remove kernels"; exit 42; }
	fi	
}

function do_install() {

	if [[ ! -e /boot/$DELETED_KERNELS_FILENAME ]]; then
		echo "Missing /boot/$DELETED_KERNELS_FILENAME to install missing kernels"
		exit 42
	fi
	if (( ! $MODE_EXECUTE )); then
		echo "Following kernels will be installed"
		while IFS= read -r line; do
			echo "sudo apt install $line"
		done < /boot/$DELETED_KERNELS_FILENAME
	else
		while IFS= read -r line; do
			sudo apt install $line
		done < /boot/$DELETED_KERNELS_FILENAME
	fi
}
	
MODE_INSTALL=0
MODE_UNINSTALL=0
MODE_EXECUTE=0

while getopts "uieh?" opt; do
    case "$opt" in
	 h|\?)
       show_help
       exit 0
		;;
    u) MODE_UNINSTALL=1
       ;;
    i) MODE_INSTALL=1
		;;
    e) MODE_EXECUTE=1
		;;
	*) echo "Unknown option $op"
		show_help
		exit 1
		;;
    esac
done

if (( $MODE_INSTALL )); then
	do_uninstall
elif (( $MODE_UNINSTALL )); then
	do_install
else
	show_help
fi	


# scratchpad

:<<'SKIP'

ls -1 /boot | grep -v -E $(uname -r | sed -E 's/arm(v[0-9]+)l?/\1/') | grep -E "^(config-|initrd|System\.map)" | xargs -0 echo

kernel.img is 32-bit for BCM2835 (RPi1, B+ & Zero)
kernel7.img is 32-bit for BCM2836 (RPi2B) and BCM2837 (RPi3iA & RPi3B & RPi3B+)
kernel7l.img is 32-bit for BCM2711 (RPi4B)
kernel8.img is 64-bit for BCM2837 (RPi3A, 3B, 2A, 3B+) or BCM2711 (RPi4)

vmlinuz-6.1.0-rpi4-rpi-v6
vmlinuz-6.1.0-rpi4-rpi-v7
vmlinuz-6.1.0-rpi4-rpi-v7l
vmlinuz-6.1.0-rpi4-rpi-v8
vmlinuz-6.1.0-rpi6-rpi-v6
vmlinuz-6.1.0-rpi6-rpi-v7
vmlinuz-6.1.0-rpi6-rpi-v7l
vmlinuz-6.1.0-rpi7-rpi-v6
vmlinuz-6.1.0-rpi7-rpi-v7
vmlinuz-6.1.0-rpi7-rpi-v7l


# script to remove kernel package(s), given kernel(s)  

given vmlinuz-6.1.0-rpi6-rpi-v7
	do: 
sudo apt purge linux-image-6.1.0-rpi6-rpi-v7

for krnl in $@
do
	pkg=linux-image${krnl#vmlinuz}
	echo "#" Removing package $pkg for kernel $krnl
	sudo apt purge $pkg
done

sudo apt autoremove

sudo apt-cache search "linux-image-" | grep -v -E "dbg|header|meta" | grep rpi

uname -r
6.1.0-rpi7-rpi-v8
sudo apt purge linux-image-6.1.0-rpi6-rpi-2712
ls /boot # kernel no longer there
sudo apt install linux-image-6.1.0-rpi6-rpi-2712
ls /boot # kernel is there again

linux-images.img-6.1.0-rpi6-rpi-2712
linux-images.img-6.1.0-rpi6-rpi-v8
linux-images.img-6.1.0-rpi7-rpi-2712

ls -1 /boot | grep -v -E $(uname -r) | grep -E "^initrd" | sed 's/initrd/linux-image/; s/\.img//' | xargs echo | tee kernels.lst; sudo mv kernels.lst /boot

SKIP
