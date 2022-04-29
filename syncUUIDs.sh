#!/bin/bash
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

dryrun=0

trap 'umount /mnt &>/dev/null' SIGINT SIGTERM EXIT

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

function updateUUIDinFstab() { # bootType uuid newUUID
	echo "Updating $1 from $2 to $3 in /etc/fstab on $rootPartition"
	(( $dryrun )) && return
	mount $rootPartition /mnt
	sed -i "s/^$1=$2/$1=$3/" /mnt/etc/fstab
	umount /mnt
}

function updateUUIDinCmdline() { # bootType uuid newUUID
	echo "Updating $1 from $2 to $3 in /boot/cmdline.txt on $bootPartition"
	(( $dryrun )) && return
	mount $bootPartition /mnt
	sed -i "s/$1=$2/$1=$3/" /mnt/cmdline.txt
	umount /mnt
}

function usage() {
	echo "Usage: $0 [-n] targetDevice" 1>&2
	echo "-n: Dont't update files. Just inform what will be updated."
	exit 1
}

# Parse arguments
while getopts ":h :n" opt; do
   case "$opt" in
		h) usage 0
			;;
		n) dryrun=1
			;;
     \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
     :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
     *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
	esac
done

shift $(( $OPTIND - 1 ))

if [[ -z $1 ]]; then
    echo "Missing device to update UUIDs"
    exit 1
fi

if [[ $USER != "root" ]]; then
	  echo "Call me as root"
	  exit 127
fi

device=$1
bootPartition="${device}1"
rootPartition="${device}2"

if [[ $device =~ [0-9]+$ ]]; then
	echo "$device is a partition but has to be a device. Try $(sed -E "s/($device)[0-9]+/\1/")"
	exit 1
fi

if [[ ! -e $device ]]; then
	echo "$device not found"
	exit 1
fi

if [[ ! -b $device ]]; then
	echo "$device no blockdevice"
	exit 1
fi

if [[ ! -e $bootPartition ]]; then
	echo "$bootPartition not found"
	exit 1
fi

if [[ ! -e $device ]]; then
	echo "$rootPartition not found"
	exit 1
fi

if ! mount $bootPartition /mnt; then
	echo "Unable to mount $bootPartition"
	exit 1
fi
umount $bootPartition &>/dev/null

if ! mount $rootPartition /mnt; then
	echo "Unable to mount $rootPartition"
	exit 1
fi
umount $rootPartition &>/dev/null

cmdline="$(parseCmdline)"
fstab="$(parseFstab)"

bootType="$(cut -d= -f1 <<< "$(grep "\-01" <<< "$fstab")")"
bootUUID="$(cut -d= -f2 <<< "$(grep "\-01" <<< "$fstab")")"
rootType="$(cut -d= -f1 <<< "$(grep "\-02" <<< "$fstab")")"
rootUUID="$(cut -d= -f2 <<< "$(grep "\-02" <<< "$fstab")")"
newBootUUID="$(parseBLKID ${device}1 $bootType | cut -d= -f2)"
newRootUUID="$(parseBLKID ${device}2 $rootType | cut -d= -f2)"

if [[ $bootUUID == $newBootUUID ]]; then
	echo "Boot $bootType $newBootUUID already used"
else
	: "Update UUID in fstab"
	updateUUIDinFstab $bootType $bootUUID $newBootUUID
fi


if [[ $rootUUID == $newRootUUID ]]; then
	echo "Root $rootType $newRootUUID already used"
else
	: "update UUID in fstab and cmdline"
	updateUUIDinFstab $rootType $rootUUID $newRootUUID
	updateUUIDinCmdline $rootType $rootUUID $newRootUUID
fi


