#!/bin/bash
#
# Small script which extracts terabytes written (TBW)
# from one SSD or all existing SSDs on a system
#
# Copyright (C) 2019 framp at linux-tips-and-tricks dot de

me=$(basename "$0")

if (( $UID != 0 )); then
	echo "Script has to be invoked as root. Use 'sudo $@'"
	exit 1
fi

if (( $# == 0 || $# > 1 )); then
	echo "Purpose: Retrieve TBW of SSDs"
	echo "Syntax:  'sudo $me -a' to retrieve TBWs of all existing SSDs"
	echo "         'sudo $me <disk>' to retrieve TBW of passed SSD"
	echo "Example: 'sudo $me /dev/sda' or 'sudo $me -a'"
	exit 1
fi

if [[ $1 == "-a" ]]; then
	lsblk | awk '$6 == "disk" { print $1; }; ' | while read disk; do
		if (( ! $(cat /sys/block/$disk/queue/rotational ) )); then
			smartctl -A "/dev/$disk" | awk -v "disk=/dev/$disk" '/^241/ { print "TBW of " disk ": "($10 * 512) * 1.0e-12, "TB" } '
		fi
	done
else
	if [[ ! -b $1 ]]; then
		echo "$1 is no disk"
		exit 1
	fi
	if [[ ! -e /sys/block/$1/queue/rotational ]] || (( $(cat /sys/block/$1/queue/rotational ) )); then
		echo "$1 is no SSD"
		exit 1
	else
		smartctl -A "/dev/$disk" | awk -v "disk=/dev/$disk" '/^241/ { print "TBW of " disk ": "($10 * 512) * 1.0e-12, "TB" } '
	fi
fi

