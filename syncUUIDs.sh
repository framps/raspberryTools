#!/bin/bash
#
#######################################################################################################################
#
#   Check and optionally update /boot/cmdline.txt and /etc/fstab on a device with installed RaspbianOS
#   with the actual UUIDs/PARTUUIDs/LABELs of the partitions. Useful if a cloned RaspbianOS fails to boot because
#   of UUID/PARTUUID/LABEL mismatch.
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

readonly VERSION="0.3"
readonly GITREPO="https://github.com/framps/raspberryTools"
readonly MYSELF=$(basename $0)
readonly MYNAME=${MYSELF##*/}

readonly CMDLINE="cmdline.txt"
readonly FSTAB="etc/fstab"
readonly MOUNTPOINT="/mnt"
readonly BOOT="/boot"
readonly BOOT_FIRMWARE="/boot/firmware"
readonly ROOT="/"
readonly ROOT_TARGET="root="
readonly LOG_FILE="$MYNAME.log"

dryrun=1                # default, enable update with option -u
verbose=0
randomize=0

mismatchDetected=0
fstabSaved=0

function cleanup() {
   umount $MOUNTPOINT &>/dev/null || true
   if [[ -e $LOG_FILE ]]; then
      cat $LOG_FILE
      rm $LOG_FILE || true
   fi
}

function error() {
   echo "??? $1"
   exit 1
}

function err() {
   echo "??? Unexpected error occured"
   local i=0
   local FRAMES=${#BASH_LINENO[@]}
   for ((i=FRAMES-2; i>=0; i--)); do
      echo '  File' \"${BASH_SOURCE[i+1]}\", line ${BASH_LINENO[i]}, in ${FUNCNAME[i+1]}
      sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i+1]}"
   done
}

function isSupportedSystem() {

    local MODELPATH=/sys/firmware/devicetree/base/model
    local RPI_ISSUE=/etc/rpi-issue

    [[ ! -e $MODELPATH ]] && return 1
    ! grep -q -i "raspberry" $MODELPATH && return 1
    [[ ! -e $RPI_ISSUE ]] && return 1
    
    return 0
}

trap 'cleanup' SIGINT SIGTERM SIGHUP EXIT
trap 'err' ERR

function isMounted() {
	grep -qs "$1" /proc/mounts
}

function parseCmdline {

    mount ${bootPartition} $MOUNTPOINT 2>/dev/null

    if [[ ! -e ${MOUNTPOINT}/${CMDLINE} ]]; then
        error "Unable to find ${MOUNTPOINT}/${CMDLINE}"
    fi

    local rootTarget=$(grep -Eo "${ROOT_TARGET}\S+=\S+" ${MOUNTPOINT}/${CMDLINE} | sed -E "s/${ROOT_TARGET}//")
    umount $MOUNTPOINT 2>/dev/null

    if [[ -z $rootTarget ]]; then
      error "Parsing of ${CMDLINE} for '${ROOT_TARGET}' failed"
    fi
    echo "$rootTarget"
}

function parseFstab {

    local tgt mnt
    local bootTgt="" rootTgt=""

    mount $rootPartition $MOUNTPOINT 2>/dev/null

    if [[ ! -e ${MOUNTPOINT}/${FSTAB} ]]; then
        error "Unable to find ${MOUNTPOINT}/${CMDLINE}"
    fi

    while read tgt mnt r; do
        case $mnt in
            $BOOT | $BOOT_FIRMWARE)
                bootTgt=$tgt
                ;;
            $ROOT)
                rootTgt=$tgt
                ;;
        esac
    done <${MOUNTPOINT}/${FSTAB}

    umount $MOUNTPOINT 2>/dev/null

    if [[ -z $bootTgt ]]; then
      error "Parsing of /${FSTAB} for '$BOOT' or '$BOOT_FIRMWARE' failed"
    fi

    if [[ -z $rootTgt ]]; then
      error "Parsing of /${FSTAB} for '$ROOT' failed"
    fi

    echo "$bootTgt $rootTgt"
}

function parseBLKID {   # device uuid/poartuuid/label
    local blkid="$(blkid $1 -o udev | grep "ID_FS_${2}=")"
    if [[ -z $blkid ]]; then
      error "Parsing of blkid $1 for filesystem type $2 failed"
    fi
    echo $blkid
}

function updateFstab() { # bootType uuid newUUID

    if (( $dryrun )); then
        echo "!!! $1 $2 should be updated to $3 in $rootPartition/$FSTAB "
        return
    fi

    mount $rootPartition $MOUNTPOINT 2>/dev/null

    if (( ! fstabSaved )); then
        echo "--- Creating fstab backup /${FSTAB}.bak on $rootPartition"
        cp ${MOUNTPOINT}/${FSTAB} ${MOUNTPOINT}/${FSTAB}.bak
        fstabSaved=1
    fi

    echo "--- Updating $1 $2 to $3 in $rootPartition/$FSTAB"

    if ! sed -i "s/^$1=$2/$1=$3/" ${MOUNTPOINT}/${FSTAB}; then
        error "??? Unable to update $rootPartition/$FSTAB"
    fi
    umount $MOUNTPOINT 2>/dev/null
}

function updateCmdline() { # bootType uuid newUUID

    if (( $dryrun )); then
        echo "!!! $1 $2 should be updated to $3 in $bootPartition/${CMDLINE}"
        return
    fi

    echo "--- Creating cmdline backup /${CMDLINE}.bak on $bootPartition"

    mount $bootPartition $MOUNTPOINT 2>/dev/null
    cp ${MOUNTPOINT}/${CMDLINE} ${MOUNTPOINT}/${CMDLINE}.bak

    echo "--- Updating $1 $2 to $3 in $bootPartition/${CMDLINE}"

    if ! sed -i  --follow-symlinks "s/$1=$2/$1=$3/" ${MOUNTPOINT}/${CMDLINE}; then
        error "??? Unable to update $bootPartition/$CMDLINE"
    fi
    umount $MOUNTPOINT 2>/dev/null
}

function randomizePartitions() {

	local answer
	
    echo -n "!!! Creating new UUID and PARTUUID on $device. Are you sure? (y|N) "
    
	read answer

	answer=${answer:0:1}	# first char only
	answer=${answer:-"n"}	# set default no

	if [[ $answer != "y"  ]]; then
		exit 1
	fi
	
	local newPARTUUID=$(od -A n -t x -N 4 /dev/urandom | tr -d " ")
    echo "--- Creating new PARTUUID $newPARTUUID on $device"
	echo -ne "x\ni\n0x$newPARTUUID\nr\nw\nq\n" | fdisk "$device" &> /dev/null
	
	local newUUID="$(od -A n -t x -N 4 /dev/urandom | tr -d " " | sed -r 's/(.{4})/\1-/')"
	newUUID="${newUUID^^*}"
	echo "--- Creating new UUID $newUUID on $bootPartition"
	printf "\x${newUUID:7:2}\x${newUUID:5:2}\x${newUUID:2:2}\x${newUUID:0:2}" | dd bs=1 seek=67 count=4 conv=notrunc of=$bootPartition # 39 for fat16, 67 for fat32

	newUUID="$(</proc/sys/kernel/random/uuid)"
    echo "--- Creating new UUID $newUUID on $rootPartition"
	e2fsck -y -f $rootPartition
	tune2fs -U "$newUUID" $rootPartition

	sync
	sleep 3
	partprobe $device
	sleep 3
	udevadm settle
}

function usage() {

   cat << EOF
$MYSELF - $VERSION ($GITREPO)

Synchronize UUIDs, PARTUUIDs or LABELs in /etc/fstab and /boot/cmdline.txt
with existing UUIDs, PARTUUIDs or LABELs of device partitions.
If no option is passed the used UUIDs, PARTUUIDs or LABELs are retrieved
and displayed only. No files are updated.

Create new UUIDs and PARTUUIDs on device partitions and update 
/etc/fstab and /boot/cmdline.txt

Usage: $0 [-nuv] device
-n: Create new random UUIDs and PARTUUIDs and sync 
	/boot/cmdline.txt and /etc/fstab afterwards
-u: Create backup of files and update the UUIDs, PARTUUIDs or LABELs in
    /boot/cmdline.txt and /etc/fstab
-v: Be verbose

Device examples: /dev/sda, /dev/mmcblk0, /dev/nvme0n1
EOF
}

#
# main
#

(( $# <= 0 )) && { usage; exit; }

echo "$MYSELF $VERSION ($GITREPO)"

while getopts ":h :n :u :v" opt; do
   case "$opt" in
        h) usage
           exit 0
           ;;
        u) dryrun=0
           ;;
        n) randomize=1
		   dryrun=0
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
    error "Missing device to update UUIDs, PARTUUIDs or LABELs"
    exit 1
fi

if (( $UID != 0 )); then
      echo "--- Please call $MYSELF as root or with sudo"
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

if ! isSupportedSystem; then
    error "$MYSELF supports Raspberries running RasbianOS only"
    exit 1
fi    

if [[ ! -e $device ]]; then
    error "$device does not exist"
    exit 1
fi

if [[ ! -b $device ]]; then
    error "$device is no blockdevice"
    exit 1
fi

if [[ ! -e $bootPartition ]]; then
    error "$bootPartition not found"
    exit 1
fi

if [[ ! -e $rootPartition ]]; then
    error "$rootPartition not found"
    exit 1
fi

if (( randomize )); then
	if isMounted $bootPartition; then
		error "$bootPartition mounted. No update possible."
		exit 1
	fi

	if isMounted $rootPartition; then
		error "$rootPartition mounted. No update possible."
		exit 1
	fi
fi

if (( $verbose )); then
   echo "... bootPartition: $bootPartition"
   echo "... rootPartition: $rootPartition"
   echo
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
   echo "... $fstabBootType on $bootPartition: $actualFstabBootUUID"
   echo "... $fstabRootType on $rootPartition: $actualFstabRootUUID"
   echo
   echo "... Boot $fstabBootType used in fstab: $fstabBootUUID"
   echo "... Root $fstabRootType used in fstab: $fstabRootUUID"
   echo "... Root $cmdlineRootType used in cmdline: $cmdlineRootUUID"
   echo
fi

if (( randomize )); then
	randomizePartitions
fi

actualCmdlineRootUUID="$(parseBLKID ${rootPartition} $cmdlineRootType | cut -d= -f2)"
actualFstabBootUUID="$(parseBLKID ${bootPartition} $fstabBootType | cut -d= -f2)"
actualFstabRootUUID="$(parseBLKID ${rootPartition} $fstabRootType | cut -d= -f2)"

if [[ $cmdlineRootUUID == $actualCmdlineRootUUID ]]; then
   echo "--- Root $fstabRootType $actualFstabRootUUID already used in $bootPartition/$CMDLINE"
else
   updateCmdline $cmdlineRootType $cmdlineRootUUID $actualCmdlineRootUUID
   mismatchDetected=1
fi

if [[ $fstabBootUUID == $actualFstabBootUUID ]]; then
   echo "--- Boot $fstabBootType $actualFstabBootUUID already used in $rootPartition/$FSTAB"
else
   updateFstab $fstabBootType $fstabBootUUID $actualFstabBootUUID
   mismatchDetected=1
fi

if [[ $fstabRootUUID == $actualFstabRootUUID ]]; then
   echo "--- Root $fstabRootType $actualFstabRootUUID already used in $rootPartition/$FSTAB"
else
   updateFstab $fstabRootType $fstabRootUUID $actualFstabRootUUID
   mismatchDetected=1
fi

if (( $mismatchDetected && dryrun)); then
   echo "!!! Use option -u to update the incorrect UUIDs, PARTUUIDs or LABELs"
fi

if (( ! $mismatchDetected && ! dryrun)); then
   echo "--- No incorrect UUIDs, PARTUUIDs or LABELs detected"
fi
