#!/bin/bash
#
#######################################################################################################################
#
#   Check and optionally update /boot/cmdline.txt and /etc/fstab on a device with installed RaspbianOS
#   with the actual UUIDs/PARTUUIDs/LABELs of the partitions.
#
#	New UUIDS and PARTUUIDs can also be generated before /boot/cmdline.txt and /etc/fstab are synced.
#
#	Useful if a cloned RaspbianOS fails to boot because of UUID/PARTUUID/LABEL mismatch or a device
#	was cloned and should become new UUIDs/PARTUUIDs.
#
#	Either download this script
#	  curl -sO https://raw.githubusercontent.com/framps/raspberryTools/master/syncUUIDs.sh
#   and invoke
#      sudo bash ./syncUUIDs.sh <options>
#
#   or use following command to directly download and invoke syncUUIDs:
#     curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/invokeTool.sh | sudo bash -s -- syncUUIDs.sh <options>
#	  	for example
#     curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/invokeTool.sh | sudo bash -s -- syncUUIDs.sh -u /dev/mmcblk0`
#
#   Copyright (C) 2022-2025 framp at linux-tips-and-tricks dot de
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

readonly VERSION="0.3.4"
readonly GITREPO="https://github.com/framps/raspberryTools"
#shellcheck disable=SC2155
#(warning): Declare and assign separately to avoid masking return values.
readonly MYSELF="$(basename "$0")"
readonly MYNAME=${MYSELF##*/}

readonly CMDLINE="cmdline.txt"
readonly FSTAB="etc/fstab"
readonly MOUNTPOINT_BOOT="/mnt/boot"
readonly MOUNTPOINT_ROOT="/mnt/root"
readonly BOOT="/boot"
readonly BOOT_FIRMWARE="/boot/firmware"
readonly ROOT="/"
readonly ROOT_TARGET="root="
readonly LOG_FILE="$MYNAME.log"

declare -r PS4='|${LINENO}> \011${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

dryrun=1 # default, enable update with option -u
verbose=0
randomize=0

mismatchDetected=0
fstabSaved=0

function cleanup() {
    local rc="$1"
    umount "$MOUNTPOINT_BOOT" &> /dev/null || true
    umount "$MOUNTPOINT_ROOT" &> /dev/null || true
    rmdir "$MOUNTPOINT_BOOT" &> /dev/null || true
    rmdir "$MOUNTPOINT_ROOT" &> /dev/null || true
    if (($rc != 0)); then
        if [[ -e "$LOG_FILE" ]]; then
            cat "$LOG_FILE"
            rm "$LOG_FILE" &> /dev/null || true
            error "Error log"
        fi
    else
        rm "$LOG_FILE" &> /dev/null || true
    fi
}

function error() {
    echo "??? $*" > /dev/tty
    exit 1
}

function info() {
    echo "--- $*"
}

function note() {
    echo "!!! $*"
}

function err() {
    local rc="$1"
    echo "??? Unexpected error occured with RC $rc"
    local i=0
    local FRAMES=${#BASH_LINENO[@]}
    for ((i = FRAMES - 2; i >= 0; i--)); do
        echo '  File' \"${BASH_SOURCE[i + 1]}\", line ${BASH_LINENO[i]}, in ${FUNCNAME[i + 1]}
        sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i + 1]}"
    done
}

function isSupportedSystem() {

    local RPI_ISSUE=$MOUNTPOINT_ROOT/etc/rpi-issue

    if [[ ! -e "$RPI_ISSUE" ]]; then
        return 1
    fi

    if [[ ! -e $MOUNTPOINT_ROOT/etc/os-release ]]; then
        return 1
    fi

    local version
    version=$(grep -E "^VERSION_ID" /etc/os-release | cut -f 2 -d "=" | sed 's/"//g')

    if ((version < 12)); then
        return 1
    fi

    return 0
}

trap 'cleanup $?' SIGINT SIGTERM SIGHUP EXIT
trap 'err $?' ERR

function isMounted() {
    grep -qs "$1" /proc/mounts
}

function parseCmdline {

    if [[ ! -e "${MOUNTPOINT_BOOT}/${CMDLINE}" ]]; then
        error "Unable to find ${MOUNTPOINT_BOOT}/${CMDLINE}"
    fi

    local rootTarget

    if ! rootTarget=$(grep -Eo "${ROOT_TARGET}\S+=\S+" ${MOUNTPOINT_BOOT}/${CMDLINE} | sed -E "s/${ROOT_TARGET}//"); then
        error "Parsing of ${CMDLINE} for '${ROOT_TARGET}' failed"
    fi

    if [[ -z $rootTarget ]]; then
        error "Parsing of ${CMDLINE} for '${ROOT_TARGET}' failed"
    fi
    echo "$rootTarget"
}

function parseFstab {

    local tgt mnt
    local bootTgt="" rootTgt=""

    if [[ ! -e "${MOUNTPOINT_ROOT}/${FSTAB}" ]]; then
        error "Unable to find ${MOUNTPOINT_ROOT}/${CMDLINE}"
    fi

    #	shellcheck disable=SC2034
    #	(warning): r appears unused. Verify use (or export if used externally).
    while read -r tgt mnt r; do
        case $mnt in
            "$BOOT" | "$BOOT_FIRMWARE")
                bootTgt=$tgt
                ;;
            "$ROOT")
                rootTgt=$tgt
                ;;
        esac
    done < "${MOUNTPOINT_ROOT}/${FSTAB}"

    if [[ -z "$bootTgt" ]]; then
        error "Parsing of /${FSTAB} for '$BOOT' or '$BOOT_FIRMWARE' failed"
    fi

    if [[ -z "$rootTgt" ]]; then
        error "Parsing of /${FSTAB} for '$ROOT' failed"
    fi

    echo "$bootTgt $rootTgt"
}

function parseBLKID { # device uuid/poartuuid/label
    local blkid
    blkid="$(blkid "$1" -o udev | grep "ID_FS_${2}=")"
    if [[ -z "$blkid" ]]; then
        error "Parsing of blkid $1 for filesystem type $2 failed"
    fi
    echo "$blkid"
}

function updateFstab() { # bootType uuid newUUID

    if (($dryrun)); then
        note "$1 $2 should be updated to $3 in $rootPartition/$FSTAB "
        return
    fi

    if ((!fstabSaved)); then
        info "Creating fstab backup /${FSTAB}.bak on $rootPartition"
        cp ${MOUNTPOINT_ROOT}/${FSTAB} ${MOUNTPOINT_ROOT}/${FSTAB}.bak
        fstabSaved=1
    fi

    info "Updating $1 $2 to $3 in $rootPartition/$FSTAB"

    if ! sed -i "s/^$1=$2/$1=$3/" ${MOUNTPOINT_ROOT}/${FSTAB}; then
        error "Unable to update $rootPartition/$FSTAB"
    fi
}

function updateCmdline() { # bootType uuid newUUID

    if (($dryrun)); then
        note "$1 $2 should be updated to $3 in $bootPartition/${CMDLINE}"
        return
    fi

    info "Creating cmdline backup /${CMDLINE}.bak on $bootPartition"

    cp ${MOUNTPOINT_BOOT}/${CMDLINE} ${MOUNTPOINT_BOOT}/${CMDLINE}.bak

    info "Updating $1 $2 to $3 in $bootPartition/${CMDLINE}"

    if ! sed -i --follow-symlinks "s/$1=$2/$1=$3/" ${MOUNTPOINT_BOOT}/${CMDLINE}; then
        error "Unable to update $bootPartition/$CMDLINE"
    fi
}

function randomizePartitions() {

    local answer

    echo -n "!!! Creating new UUID and PARTUUID on $device. Are you sure? (y|N) "

    read -r answer

    answer=${answer:0:1}  # first char only
    answer=${answer:-"n"} # set default no

    if [[ $answer != "y" ]]; then
        exit 1
    fi

    local newPARTUUID
    newPARTUUID=$(od -A n -t x -N 4 /dev/urandom | tr -d " ")
    info "Creating new PARTUUID $newPARTUUID on $device"
    echo -ne "x\ni\n0x$newPARTUUID\nr\nw\nq\n" | fdisk "$device" &>> "$LOG_FILE"

    local newUUID
    newUUID="$(od -A n -t x -N 4 /dev/urandom | tr -d " " | sed -r 's/(.{4})/\1-/')"
    newUUID="${newUUID^^*}"
    info "Creating new UUID $newUUID on $bootPartition"
    printf "\x${newUUID:7:2}\x${newUUID:5:2}\x${newUUID:2:2}\x${newUUID:0:2}" | dd bs=1 seek=67 count=4 conv=notrunc of=$bootPartition &>> $LOG_FILE

    newUUID="$(< /proc/sys/kernel/random/uuid)"
    info "Creating new UUID $newUUID on $rootPartition"
    if ! umount "$MOUNTPOINT_ROOT"; then
        error "Unable to umount $MOUNTPOINT_ROOT"
    fi
    e2fsck -y -f "$rootPartition" &>> "$LOG_FILE"
    tune2fs -U "$newUUID" "$rootPartition" &>> "$LOG_FILE"
    if ! mount "$rootPartition" "$MOUNTPOINT_ROOT"; then
        error "Unable to mount $rootPartition"
    fi

    sync
    sleep 3
    partprobe "$device"
    sleep 3
    udevadm "settle"
}

function usage() {

    cat << EOF
$MYSELF - $VERSION ($GITREPO)

Synchronize UUIDs, PARTUUIDs or LABELs in /etc/fstab and /boot/cmdline.txt
with existing UUIDs, PARTUUIDs or LABELs of device partitions.
If no option is passed the used UUIDs, PARTUUIDs or LABELs are retrieved
and displayed only. No files are updated.

Create new UUIDs and PARTUUIDs on device partitions and update
/etc/fstab and /boot/cmdline.txt.

Usage: $0 [-n | -u]? [-v]? device
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

(($# <= 0)) && {
    usage
    exit
}

echo "$MYSELF $VERSION ($GITREPO)"

rm "$LOG_FILE" &> /dev/null || true

while getopts ":h :n :u :v" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        u)
            dryrun=0
            ;;
        n)
            randomize=1
            dryrun=0
            ;;
        v)
            verbose=1
            ;;
        \?)
            echo "Unknown option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Missing option argument for -$OPTARG" >&2
            exit 1
            ;;
        *)
            echo "Unimplemented option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

shift $(($OPTIND - 1))

if [[ -z $1 ]]; then
    error "Missing device to update UUIDs, PARTUUIDs or LABELs"
fi

if (($UID != 0)); then
    info "Please invoke $MYSELF as root or with sudo"
    exit
fi

device=$1

if [[ ! -e "$device" ]]; then
    error "$device does not exist"
fi

if [[ ! -b "$device" ]]; then
    error "$device is no blockdevice"
fi

case $device in

    /dev/sd*)
        bootPartition="${device}1"
        rootPartition="${device}2"
        ;;

    /dev/mmcblk* | /dev/nvme*)
        bootPartition="${device}p1"
        rootPartition="${device}p2"
        ;;

    *)
        echo "Invalid device $device"
        echo "Device examples: /dev/sda, /dev/mmcblk0, /dev/nvme0n1"
        exit 1
        ;;
esac

if [[ ! -e "$bootPartition" ]]; then
    error "$bootPartition not found"
fi

if [[ ! -e "$rootPartition" ]]; then
    error "$rootPartition not found"
fi

if ((randomize)); then
    if isMounted "$bootPartition"; then
        error "$bootPartition mounted. No update possible."
    fi

    if isMounted "$rootPartition"; then
        error "$rootPartition mounted. No update possible."
    fi
fi

if (($verbose)); then
    info "bootPartition: $bootPartition"
    info "rootPartition: $rootPartition"
    echo
fi

if ! mkdir "$MOUNTPOINT_BOOT"; then
    error "Unable to mkdir $MOUNTPOINT_BOOT"
fi

if ! mount "$bootPartition" "$MOUNTPOINT_BOOT"; then
    error "Unable to mount $bootPartition"
fi

if ! mkdir "$MOUNTPOINT_ROOT"; then
    error "Unable to mkdir $MOUNTPOINT_ROOT"
fi

if ! mount "$rootPartition" "$MOUNTPOINT_ROOT"; then
    error "Unable to mount $rootPartition"
fi

if ! isSupportedSystem; then
    error "$MYSELF supports Raspberries running RasbianOS Bookworm only"
fi

cmdline=$(parseCmdline)
IFS=" " read -r -a fstab <<< "$(parseFstab)"

cmdlineRootType="$(cut -d= -f1 <<< "$cmdline")"
cmdlineRootUUID="$(cut -d= -f2 <<< "$cmdline")"
fstabBootType="$(cut -d= -f1 <<< "${fstab[0]}")"
fstabBootUUID="$(cut -d= -f2 <<< "${fstab[0]}")"
fstabRootType="$(cut -d= -f1 <<< "${fstab[1]}")"
fstabRootUUID="$(cut -d= -f2 <<< "${fstab[1]}")"

actualCmdlineRootUUID="$(parseBLKID "${rootPartition}" "$cmdlineRootType" | cut -d= -f2)"
actualFstabBootUUID="$(parseBLKID "${bootPartition}" "$fstabBootType" | cut -d= -f2)"
actualFstabRootUUID="$(parseBLKID "${rootPartition}" "$fstabRootType" | cut -d= -f2)"

if [[ -z $actualCmdlineRootUUID ||
    -z $actualFstabBootUUID ||
    -z $actualFstabRootUUID ||
    -z $cmdlineRootType ||
    -z $cmdlineRootUUID ||
    -z $fstabBootType ||
    -z $fstabBootUUID ||
    -z $fstabRootType ||
    -z $fstabRootUUID ]] \
    ; then
    echo "??? ASSERTION FAILED: Unable to collect required data"
    exit 1
fi

if (($verbose)); then
    echo "... $fstabBootType on $bootPartition: $actualFstabBootUUID"
    echo "... $fstabRootType on $rootPartition: $actualFstabRootUUID"
    echo
    echo "... Boot $fstabBootType used in fstab: $fstabBootUUID"
    echo "... Root $fstabRootType used in fstab: $fstabRootUUID"
    echo "... Root $cmdlineRootType used in cmdline: $cmdlineRootUUID"
    echo
fi

if ((randomize)); then
    randomizePartitions
fi

actualCmdlineRootUUID="$(parseBLKID "${rootPartition}" "$cmdlineRootType" | cut -d= -f2)"
actualFstabBootUUID="$(parseBLKID "${bootPartition}" "$fstabBootType" | cut -d= -f2)"
actualFstabRootUUID="$(parseBLKID "${rootPartition}" "$fstabRootType" | cut -d= -f2)"

if [[ $cmdlineRootUUID == "$actualCmdlineRootUUID" ]]; then
    info "Root $fstabRootType $actualFstabRootUUID already used in $bootPartition/$CMDLINE"
else
    updateCmdline "$cmdlineRootType" "$cmdlineRootUUID" "$actualCmdlineRootUUID"
    mismatchDetected=1
fi

if [[ $fstabBootUUID == "$actualFstabBootUUID" ]]; then
    info "Boot $fstabBootType $actualFstabBootUUID already used in $rootPartition/$FSTAB"
else
    updateFstab "$fstabBootType" "$fstabBootUUID" "$actualFstabBootUUID"
    mismatchDetected=1
fi

if [[ $fstabRootUUID == "$actualFstabRootUUID" ]]; then
    info "Root $fstabRootType" "$actualFstabRootUUID" already used in "$rootPartition/$FSTAB"
else
    updateFstab "$fstabRootType" "$fstabRootUUID" "$actualFstabRootUUID"
    mismatchDetected=1
fi

if (($mismatchDetected && $dryrun)); then
    note "Use option -u to update the incorrect UUIDs, PARTUUIDs or LABELs"
fi

if ((!$mismatchDetected && !$dryrun)); then
    info "No incorrect UUIDs, PARTUUIDs or LABELs detected"
fi
