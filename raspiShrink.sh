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

imageFile="$1"

fdisk -l "imageFile"

loopDevice=$(losetup --show -f --partscan $imageFile)

minimumSize=$(resize2fs -P ${loopDevice}p2)

exit

sudo e2fsck -p -f /dev/loop22p2 && sudo resize2fs /dev/loop22p2 750000

echo +$((750000*4))K

sudo losetup -d /dev/loop22*

fdisk -l /home/hanno/rasppi_20210429_SHRUNK.img

END=6098943
truncate -s $(((END+1)*512)) /home/hanno/rasppi_20210429_SHRUNK.img

ls -lh /home/hanno/rasppi_20210429_SHRUNK.img

