#!/bin/bash

#######################################################################################################################
#
#   Truncate an Raspberry image with two partitions to it's minimum size
#
#	Algorithm based on https://www.hoowl.se/shrinking_an_sd_card_image.html
#
#   Copyright (C) 2024 framp at linux-tips-and-tricks dot de
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

readonly VERSION="0.1"
readonly GITREPO="https://github.com/framps/raspberryTools"
readonly MYSELF=$(basename $0)
readonly MYNAME=${MYSELF##*/}

loopDevice=""

function err() {
   echo "??? Unexpected error occured"
   local i=0
   local FRAMES=${#BASH_LINENO[@]}
   for ((i=FRAMES-2; i>=0; i--)); do
      echo '  File' \"${BASH_SOURCE[i+1]}\", line ${BASH_LINENO[i]}, in ${FUNCNAME[i+1]}
      sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i+1]}"
   done
}

# Borrowed from http://unix.stackexchange.com/questions/44040/a-standard-tool-to-convert-a-byte-count-into-human-kib-mib-etc-like-du-ls1

function bytesToHuman() {
	local b d s S
	local sign=1
	b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,E,P,Y,Z}iB)
	if (( b < 0 )); then
		sign=-1
		(( b=-b ))
	fi
	while ((b > 1024)); do
		d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
		b=$((b / 1024))
		let s++
	done
	if (( sign < 0 )); then
		(( b=-b ))
	fi
	echo "$b$d ${S[$s]}"
}

function cleanup() {
   if [[ -n $loopDevice ]]; then
		losetup -D $loopDevice
   fi
}

function usage() {

   cat <<- EOF
   $MYSELF - $VERSION ($GITREPO)

    Shrink a Rasperry image as small as possible

    Usage: $0 image
EOF
}

function error() {
   echo "??? $1"
   exit 1
}

trap 'err' ERR
trap 'cleanup' SIGINT SIGTERM SIGHUP EXIT

(( $# <= 0 )) && { usage; exit; }

if (( $UID != 0 )); then
      echo "--- Please call $MYSELF as root or with sudo"
      exit 1
fi

echo "$MYSELF $VERSION ($GITREPO)"

imageFile="$1"

if [[ ! -f $imageFile ]]; then
	error "$imageFile not found"
fi	

#fdisk -l "$imageFile"

currentSize=$(ls -lh $imageFile | cut -f 5 -d ' ')
echo "CurrentSize: $currentSize"

loopDevice=$(losetup --show -f --partscan $imageFile)

minimumSize=$(resize2fs -P ${loopDevice}p2 2>/dev/null | egrep -o "[0-9]+")

blockSize=$(tune2fs -l ${loopDevice}p2 | egrep -i "block size" | cut -f 2 -d ':')

minimumSizeInBytes=$((minimumSize * $blockSize))

echo "MinimumSize: $(bytesToHuman $minimumSizeInBytes)"

exit

sudo e2fsck -p -f /dev/loop22p2 && sudo resize2fs /dev/loop22p2 750000

echo +$((750000*4))K

sudo losetup -d /dev/loop22*

fdisk -l /home/hanno/rasppi_20210429_SHRUNK.img

END=6098943
truncate -s $(((END+1)*512)) /home/hanno/rasppi_20210429_SHRUNK.img

ls -lh /home/hanno/rasppi_20210429_SHRUNK.img

