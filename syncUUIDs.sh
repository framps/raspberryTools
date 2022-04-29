#!/bin/bash
#
# NOTE: Script still under construction
#
#######################################################################################################################
#
# 	Update /boot/cmdline.txt and /etc/fstab on a target device with the actual UUID/PARTUUIDs of the target device
#
#   Copyright (C) 2022 framp at linux-tips-and-tricks dot de
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################################################################

function parseCmdline {
	mount $bootPartition /mnt
	local uuidTypeCmdline=$(grep -Eo "root=\S+" /mnt/cmdline.txt | sed -E "s/root=([^=]+)=(.+)/\1=\2/")
	umount /mnt

	echo "$uuidTypeCmdline"
}

function parseFstab {

	local tgt mnt
	local bootTgt rootTgt
	local bootType rootType
	mount $rootPartition /mnt

	while read tgt mnt r; do
		case $mnt in
			/boot)
				bootTgt=$tgt
				;;
			/)
				rootTgt=$tgt
				;;
		esac
	done </mnt/etc/fstab

	umount /mnt

	echo "$bootTgt"
	echo "$rootTgt"
}

function parseBLKID {	# device uuidType

	local blkid="$(blkid $1 -o udev | grep "ID_FS_${2}=")"
	echo $blkid
}

function usage() {
	echo "Usage: $0 -b <bootPartition> -r <rootPartition> target" 1>&2
	exit 1
}

# Parse arguments
while getopts ":h :b: :r:" opt; do
   case "$opt" in
		h) usage 0
			;;
		b) bootPartition=$OPTARG
			;;
		r) rootPartition=$OPTARG
			;;
     \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
     :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
     *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;

	esac
done

#if (( $OPTIND == 3 )); then
#    echo "Not enough options specified"
#    exit 1
#fi

shift $(( $OPTIND - 1 ))

if [[ $USER != "root" ]]; then
	  echo "Call me as root"
	  exit 127
fi

if (( $# == 0 )); then
	if [[ ! -b $bootPartition ]]; then
		echo "Bootpartition $bootPartition not found"
		exit 1
	fi

	if [[ ! -b $rootPartition ]]; then
		echo "Rootpartition $rootPartition not found"
		exit 1
	fi
else
	device=$1
	bootPartition="${device}1"
	rootPartition="${device}2"
fi

echo "Bootpartition: $bootPartition"
echo "Rootpartition: $rootPartition"

cmdline="$(parseCmdline)"
fstab="$(parseFstab)"

bootType="$(cut -d= -f1 <<< "$(grep "\-01" <<< "$fstab")")"
bootUUID="$(cut -d= -f2 <<< "$(grep "\-01" <<< "$fstab")")"
rootType="$(cut -d= -f1 <<< "$(grep "\-02" <<< "$fstab")")"
rootUUID="$(cut -d= -f2 <<< "$(grep "\-02" <<< "$fstab")")"
newBootUUID="$(parseBLKID ${device}1 $bootType | cut -d= -f2)"
newRootUUID="$(parseBLKID ${device}2 $rootType | cut -d= -f2)"

if [[ $bootUUID == $newBootUUID ]]; then
	echo "Boot UUID already OK"
else
	: "Update UUID in fstab"
fi


if [[ $rootUUID == $newRootUUID ]]; then
	echo "Root UUID already OK"
else
	: "update UUID in fstab and cmdline"
fi


