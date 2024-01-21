#!/bin/bash
#
#######################################################################################################################
#
#   Check and optionally update /boot/cmdline.txt and /etc/fstab on a device with RaspbianOS installed
#   with the actual UUIDs/PARTUUIDs of the device. Useful if a cloned RaspbianOS fails to boot because
#   of UUID/PARTUUID mismatch.
#
#   Copyright (C) 2022-2024 framp at linux-tips-and-tricks dot de
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

set -euo pipefail

readonly VERSION="0.1.1"
readonly MYSELF=$(basename $0)

readonly CMDLINE="cmdline.txt"
readonly FSTAB="etc/fstab"
readonly MOUNTPOINT="/mnt"

dryrun=1                # default, enable update with option -u
verbose=0

mismatchDetected=0      
fstabSaved=0

trap 'umount $MOUNTPOINT &>/dev/null' SIGINT SIGTERM EXIT

function parseCmdline {

    mount $bootPartition $MOUNTPOINT 2>/dev/null

   	if [[ ! -e ${MOUNTPOINT}/${CMDLINE} ]]; then
        echo "??? Unable to find ${MOUNTPOINT}/${CMDLINE}"
        exit 42
	fi

    local rootTarget=$(grep -Eo "root=\S+=\S+" ${MOUNTPOINT}/${CMDLINE} | sed -E "s/root=//")
    umount $MOUNTPOINT 2>/dev/null
    echo "$rootTarget"
}

function parseFstab {

    local tgt mnt
    local bootTgt rootTgt
    local bootType rootType

    mount $rootPartition $MOUNTPOINT 2>/dev/null

   	if [[ ! -e ${MOUNTPOINT}/${FSTAB} ]]; then
        echo "??? Unable to find ${MOUNTPOINT}/${CMDLINE}"
        exit 42
	fi

    while read tgt mnt r; do
        case $mnt in
            /boot | /boot/firmware)
                bootTgt=$tgt
                ;;
            /)
                rootTgt=$tgt
                ;;
        esac
    done <${MOUNTPOINT}/${FSTAB}

    umount $MOUNTPOINT 2>/dev/null

    echo "$bootTgt $rootTgt"
}

function parseBLKID {   # device uuidType
    local blkid="$(blkid $1 -o udev | grep "ID_FS_${2}=")"
    echo $blkid
}

function updateUUIDinFstab() { # bootType uuid newUUID

    if (( $dryrun )); then
        echo "!!! $1 $2 should be updated to $3 in $rootPartition/$FSTAB "
        return
    fi

    mount $rootPartition $MOUNTPOINT 2>/dev/null

    if (( ! fstabSaved )); then
        echo "--- Creating fstab backup ${FSTAB}.bak on $rootPartition"
        cp ${MOUNTPOINT}/${FSTAB} ${MOUNTPOINT}/${FSTAB}.bak
        fstabSaved=1
    fi
    echo "--- Updating $1 $2 to $3 in $rootPartition/$FSTAB"
    if ! sed -i --follow-symlinks  "s/^$1=$2/$1=$3/" ${MOUNTPOINT}/${FSTAB}; then
        echo "??? Unable to update $rootPartition/$FSTAB"
        exit 1
    fi
    umount $MOUNTPOINT 2>/dev/null
}

function updateUUIDinCmdline() { # bootType uuid newUUID
    if (( $dryrun )); then
        echo "!!! $1 $2 should be updated to $3 in $bootPartition/$CMDLINE"
        return
    fi
    echo "--- Creating cmdline backup ${CMDLINE}.bak on $bootPartition"
    mount $bootPartition $MOUNTPOINT 2>/dev/null
    cp ${MOUNTPOINT}/${CMDLINE} ${MOUNTPOINT}/${CMDLINE}.bak
    echo "--- Updating $1 $2 to $3 in $bootPartition/cmdline.txt"
    if ! sed -i  --follow-symlinks "s/$1=$2/$1=$3/" ${MOUNTPOINT}/${CMDLINE}; then
        echo "??? Unable to update $bootPartition/$CMDLINE"
        exit 1
    fi
    umount $MOUNTPOINT 2>/dev/null
}

function usage() {
	cat <<- EOF
	$MYSELF - $VERSION
    
    Synchronize UUIDs or PARTUUIDs in /etc/fstab and /boot/cmdline.txt
    with existing UUIDs or PARTUUIDs of device partitions.
    If no option is passed the used UUIDs or PARTUUIDs are retrieved
    and displayed only. No files are updated.
    
    Usage: $0 [-uv] device
    -u: Create backup of files and update the UUIDs and PARTUUIDs in
        /etc/cmdline.txt and /etc/fstab
    -v: Verbose output"
    
    Device examples: /dev/sda, /dev/mmcblk0, /dev/nvme0n1
EOF
    exit 0
}

#
# main
#

(( $# <= 0 )) && { usage; exit; }

while getopts ":h :u :v" opt; do
   case "$opt" in
        h) usage
           exit 0
           ;;
        u) dryrun=0
           ;;
        v) verbose=1
		   ;;
     \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
     :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
     *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
    esac
done

shift $(( $OPTIND - 1 ))

if [[ -z $1 ]]; then
    echo "??? Missing device to update UUIDs"
    exit 1
fi

if (( $UID != 0 )); then
      echo "--- Call me as root or with sudo"
      exit 1
fi

device=$1

case $device in

    /dev/sd*)
        bootPartition="${device}1"
        rootPartition="${device}2"
        ;;
    /dev/mmcblk*|/dev/nvme*)
        bootPartition="${device}p1"
        rootPartition="${device}p2"
        ;;
    *)
        echo "Invalid device $device"
        echo "Device examples: /dev/sda, /dev/mmcblk0, /dev/nvme0n1"
        exit 1
esac

if [[ ! -e $device ]]; then
    echo "??? $device does not exist"
    exit 1
fi

if [[ ! -b $device ]]; then
    echo "??? $device is no blockdevice"
    exit 1
fi

if [[ ! -e $bootPartition ]]; then
    echo "??? $bootPartition not found"
    exit 1
fi

if [[ ! -e $rootPartition ]]; then
    echo "??? $rootPartition not found"
    exit 1
fi

if ! mount $bootPartition /mnt 2>/dev/null; then
    echo "??? Unable to mount $bootPartition"
    exit 1
fi
umount $bootPartition &>/dev/null

if ! mount $rootPartition /mnt 2>/dev/null; then
    echo "??? Unable to mount $rootPartition"
    exit 1
fi
umount $rootPartition &>/dev/null

cmdline=$(parseCmdline)
fstab=( $(parseFstab) )

cmdlineRootType="$(cut -d= -f1 <<< $cmdline)"
cmdlineRootUUID="$(cut -d= -f2 <<< $cmdline)"
fstabBootType="$(cut -d= -f1 <<< "${fstab[0]}")"
fstabBootUUID="$(cut -d= -f2 <<< "${fstab[0]}")"
fstabRootType="$(cut -d= -f1 <<< "${fstab[1]}")"
fstabRootUUID="$(cut -d= -f2 <<< "${fstab[1]}")"

actualCmdlineRootUUID="$(parseBLKID ${rootPartition} $cmdlineRootType | cut -d= -f2)"
actualFstabBootUUID="$(parseBLKID ${bootPartition} $fstabBootType | cut -d= -f2)"
actualFstabRootUUID="$(parseBLKID ${rootPartition} $fstabRootType | cut -d= -f2)"

if [[ -z $actualCmdlineRootUUID || \
		-z $actualFstabBootUUID || \
		-z $actualFstabRootUUID || \
		-z $cmdlineRootType || \
		-z $cmdlineRootUUID || \
		-z $fstabBootType || \
		-z $fstabBootUUID || \
		-z $fstabRootType || \
		-z $fstabRootUUID \
	]]; then
		echo "??? ASSERTION FAILED: Unable to collect required data"
	exit 1
fi	

if (( $verbose )); then
	echo "--- $cmdlineRootType $cmdlineRootUUID used in $bootPartition/cmdline"
	echo "--- $fstabBootType $fstabBootUUID used in $rootPartition/fstab"
	echo "--- $fstabRootType $fstabRootUUID used in $rootPartition/fstab"
	echo
fi


if [[ $cmdlineRootUUID == $actualCmdlineRootUUID ]]; then
    echo "--- Root $fstabRootType $actualFstabRootUUID already used in $bootPartition/$CMDLINE"
else
	updateUUIDinCmdline $cmdlineRootType $cmdlineRootUUID $actualCmdlineRootUUID
    mismatchDetected=1
fi	

if [[ $fstabBootUUID == $actualFstabBootUUID ]]; then
    echo "--- Boot $fstabBootType $actualFstabBootUUID already used in $rootPartition/$FSTAB"
else
	updateUUIDinFstab $fstabBootType $fstabBootUUID $actualFstabBootUUID
    mismatchDetected=1
fi	
    
if [[ $fstabRootUUID == $actualFstabRootUUID ]]; then
    echo "--- Root $fstabRootType $actualFstabRootUUID already used in $rootPartition/$FSTAB"
else
	updateUUIDinFstab $fstabRootType $fstabRootUUID $actualFstabRootUUID
    mismatchDetected=1
fi

if (( $mismatchDetected && dryrun)); then
    echo "!!! Use option -u to update the incorrect UUIDs or PARTUUIDs"
fi
