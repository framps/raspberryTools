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

readonly CMDLINE="/cmdline.txt"
readonly FSTAB="/etc/fstab"
readonly MOUNTPOINT="/mnt"

dryrun=1                # default, enable update with option -u
mismatchDetected=0      
fstabSaved=0

trap 'umount $MOUNTPOINT &>/dev/null' SIGINT SIGTERM EXIT

function parseCmdline {
    mount $bootPartition $MOUNTPOINT 2>/dev/null
    local uuidTypeCmdline=$(grep -Eo "root=\S+" ${MOUNTPOINT}${CMDLINE} | sed -E "s/root=([^=]+)=(.+)/\1=\2/")
    umount $MOUNTPOINT 2>/dev/null
    echo "$uuidTypeCmdline"
}

function parseFstab {

    local tgt mnt
    local bootTgt rootTgt
    local bootType rootType

    mount $rootPartition $MOUNTPOINT 2>/dev/null

    while read tgt mnt r; do
        case $mnt in
            /boot | /boot/firmware)
                bootTgt=$tgt
                ;;
            /)
                rootTgt=$tgt
                ;;
        esac
    done <${MOUNTPOINT}${FSTAB}

    umount $MOUNTPOINT 2>/dev/null

    echo "$bootTgt"
    echo "$rootTgt"
}

function parseBLKID {   # device uuidType
    local blkid="$(blkid $1 -o udev | grep "ID_FS_${2}=")"
    echo $blkid
}

function updateUUIDinFstab() { # bootType uuid newUUID

    if (( $dryrun )); then
        echo "$1 $2 should be updated to $3 in $FSTAB on $rootPartition"
        return
    fi

    mount $rootPartition $MOUNTPOINT 2>/dev/null

    if (( ! fstabSaved )); then
        echo "Creating fstab backup ${FSTAB}.bak on $rootPartition"
        cp /mnt/etc/fstab ${MOUNTPOINT}${FSTAB}.bak
        fstabSaved=1
    fi
    echo "Updating $1 $2 to $3 in $FSTAB on $rootPartition"
    if ! sed -i --follow-symlinks  "s/^$1=$2/$1=$3/" ${MOUNTPOINT}${FSTAB}; then
        echo "??? Unable to update $FSTAB"
        exit 1
    fi
    umount $MOUNTPOINT 2>/dev/null
}

function updateUUIDinCmdline() { # bootType uuid newUUID
    if (( $dryrun )); then
        echo "$1 $2 should be updated to $3 in $CMDLINE on $bootPartition"
        return
    fi
    echo "Creating cmdline backup ${CMDLINE}.bak on $bootPartition"
    mount $bootPartition $MOUNTPOINT 2>/dev/null
    cp /mnt/cmdline.txt ${MOUNTPOINT}${CMDLINE}.bak
    echo "Updating $1 $2 to $3 in cmdline.txt on $bootPartition"
    if ! sed -i  --follow-symlinks "s/$1=$2/$1=$3/" ${MOUNTPOINT}${CMDLINE}; then
        echo "??? Unable to update $CMDLINE"
        exit 1
    fi
    umount $MOUNTPOINT 2>/dev/null
}

function usage() {
    echo
    echo "Synchronize UUIDs or PARTUUIDs in /etc/fstab and /boot/cmdline.txt"
    echo "with existing UUIDs or PARTUUIDs of device partitions."
    echo "If no option is passed the used UUIDs or PARTUUIDs are retrieved"
    echo "and displayed only. No files are updated."
    echo
    echo "Usage: $0 [-u] device"
    echo "-u: Create backup of files and update the UUIDs"
    echo
    echo "Device examples: /dev/sda, /dev/mmcblk0, /dev/nvme0n1"
    exit 0
}

#
# main
#

(( $# <= 0 )) && { usage; exit; }

while getopts ":h :u" opt; do
   case "$opt" in
        h) usage
           exit 0
           ;;
        u) dryrun=0
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

if (( $UID != 0 )); then
      echo "Call me as root or with sudo"
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
    echo "$device does not exist"
    exit 1
fi

if [[ ! -b $device ]]; then
    echo "$device is no blockdevice"
    exit 1
fi

if [[ ! -e $bootPartition ]]; then
    echo "$bootPartition not found"
    exit 1
fi

if [[ ! -e $rootPartition ]]; then
    echo "$rootPartition not found"
    exit 1
fi

if ! mount $bootPartition /mnt 2>/dev/null; then
    echo "Unable to mount $bootPartition"
    exit 1
fi
umount $bootPartition &>/dev/null

if ! mount $rootPartition /mnt 2>/dev/null; then
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
newBootUUID="$(parseBLKID ${bootPartition} $bootType | cut -d= -f2)"
newRootUUID="$(parseBLKID ${rootPartition} $rootType | cut -d= -f2)"

[[ -z "$bootType" ]] && { echo "bootType not discovered"; exit; }
[[ -z "$rootType" ]] && { echo "rootType not discovered"; exit; }
[[ -z "$bootUUID" ]] && { echo "bootUUID not discovered"; exit; }
[[ -z "$rootUUID" ]] && { echo "rootUUID not discovered"; exit; }
[[ -z "$newBootUUID" ]] && { echo "newBootUUID not discovered"; exit; }
[[ -z "$newRootUUID" ]] && { echo "newRootUUID not discovered"; exit; }

echo "$bootPartition has $bootType $bootUUID"
echo "$rootPartition has $rootType $rootUUID"

if [[ $bootUUID == $newBootUUID ]]; then
    echo "Boot $bootType $newBootUUID already used in $FSTAB"
else
    updateUUIDinFstab $bootType $bootUUID $newBootUUID
    mismatchDetected=1
fi

if [[ $rootUUID == $newRootUUID ]]; then
    echo "Root $rootType $newRootUUID already used in $FSTAB and $CMDLINE"
else
    updateUUIDinFstab $rootType $rootUUID $newRootUUID
    updateUUIDinCmdline $rootType $rootUUID $newRootUUID
    mismatchDetected=1
fi

if (( $mismatchDetected && dryrun)); then
    echo "Use option -u to update the incorrect UUIDs or PARTUUIDs"
fi
