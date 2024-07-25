#!/bin/bash

#######################################################################################################################
#
#    Switch boot device on CM4 with multiple OS
#    For example from /dev/mmcblk0 to /dev/nvme0n1 and vice versa
#	 The last two characters of the BOOT_ORDER are swapped and a reboot is initiated
#
#######################################################################################################################
#
#    Copyright (c) 2024 framp at linux-tips-and-tricks dot de
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

set -euo pipefail

readonly VERSION=0.1
readonly GITREPO="https://github.com/framps/raspberryTools"
readonly MYSELF="$(basename "$0")"
readonly MYNAME=${MYSELF%.*}

readonly BOOTORDER1="16"
readonly BOOTORDER2="${BOOTORDER1:1:1}${BOOTORDER1:0:1}"

readonly MODELPATH=/sys/firmware/devicetree/base/model

if ! [[ -e $MODELPATH ]] || ! grep -q -i "raspberry" $MODELPATH; then
	echo "$MYNAME works on Raspberries only"
	exit 1
fi

if (( $# >= 1 )) && [[ "$1" =~ ^(-h|--help|-\?)$ ]]; then
	cat << EOH
	$MYSELF $VERSION ($GITREPO)
Usage:
	$MYSELF                       Switch os boot device
	$MYSELF -h | -? | --help      Show this help text

EOH
	exit 0
fi

echo "$MYSELF $VERSION ($GITREPO)"

configFile=$(mktemp)					# temp file for config change

trap "{ rm $configFile; }" EXIT SIGINT SIGTERM 			# cleanup on exit

rpi-eeprom-config --out $configFile			# retrive current config

set +e
oldBootorder="$(grep "^BOOT_ORDER=" "$configFile")"	# retrieve BOOT_ORDER line
(( $? )) && { echo "Unable to find BOOT_ORDER line in config"; exit 1; }
set -e

oldBoot=${oldBootorder: -2} 				# extract last boot chars
[[ $oldBoot != "$BOOTORDER1" && $oldBoot != "$BOOTORDER2" ]] && { echo "Unable to extract old boot sequence"; exit 1; }

newBoot="${oldBoot:1:1}${oldBoot:0:1}" # switch boot order

set +e
sed -i "s/$oldBoot/$newBoot/" "$configFile"
(( $? )) && { echo "Unable to edit old config"; exit 1; }
set -e

newBootorder="$(grep "^BOOT_ORDER=" "$configFile")"	# retrieve BOOT_ORDER line
echo "Updated BOOT_ORDER from $oldBootorder to $newBootorder"

sudo rpi-eeprom-config --apply "$configFile"
sudo shutdown -r now
