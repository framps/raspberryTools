#!/bin/bash
#
#######################################################################################################################
#
# 	 Small script which extracts terabytes written (TBW)
# 	 from one SSD or all existing SSDs on a system
#
# 	 Copyright (C) 2019 framp at linux-tips-and-tricks dot de
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

MYSELF=$(basename "$0")
VERSION="0.1"
GITREPO="https://github.com/framps/raspberryTools"

echo "$MYSELF $VERSION ($GITREPO)"

if (($UID != 0)); then
    echo "Script has to be invoked as root. Use 'sudo $@'"
    exit 1
fi

if (($# == 0 || $# > 1)); then
    echo "Purpose: Retrieve TBW of SSDs"
    echo "Syntax:  'sudo $me -a' to retrieve TBWs of all existing SSDs"
    echo "         'sudo $me <disk>' to retrieve TBW of passed SSD"
    echo "Example: 'sudo $me /dev/sda' or 'sudo $me -a'"
    exit 1
fi

# Borrowed from http://unix.stackexchange.com/questions/44040/a-standard-tool-to-convert-a-byte-count-into-human-kib-mib-etc-like-du-ls1

function bytesToHuman() {
    local b d s S
    local sign=1
    b=${1:-0}
    d=''
    s=0
    S=(Bytes {K,M,G,T,E,P,Y,Z}iB)
    if ((b < 0)); then
        sign=-1
        ((b = -b))
    fi
    while ((b > 1024)); do
        d="$(printf ".%02d" $((b % 1024 * 100 / 1024)))"
        b=$((b / 1024))
        let s++
    done
    if ((sign < 0)); then
        ((b = -b))
    fi
    echo "$b$d ${S[$s]}"
}

function echoTBW() { # disk (no /dev)
    if ((!$(cat /sys/block/$1/queue/rotational))); then
        sectorSize=$(smartctl /dev/$1 --all | grep "Sector Size" | awk '{ print $3 } ')
        totalLBAsWritten=$(smartctl -A "/dev/$1" | awk -v disk="/dev/$1" -v sectorSize="$sectorSize" '/^241/ { print ($10 * sectorSize) } ')
        echo "TBW of $1: $(bytesToHuman $totalLBAsWritten)"
    fi
}

if [[ $1 == "-a" ]]; then
    lsblk | awk '$6 == "disk" { print $1; }; ' | while read disk; do
        echoTBW "$disk"
    done
else
    if [[ ! -b $1 ]]; then
        echo "$1 is no disk"
        exit 1
    fi
    part=${1#"/dev/"}
    if [[ ! -e /sys/block/$part/queue/rotational ]] || (($(cat /sys/block/$part/queue/rotational))); then
        echo "$1 is no SSD"
        exit 1
    else
        echoTBW "$part"
    fi
fi
