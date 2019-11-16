#!/bin/bash
#
# Small script which extracts the Terabytes written (TBW)
# from an SSD
#
# Copyright (C) 2019 framp at linux-tips-and-tricks dot de

me=$(basename "$0")

if (( $# != 1 )); then
	echo "Purpose: Display TBW of an SSD"
	echo "Syntax:  $me <device>"
	echo "Example: sudo getTWB.sh /dev/sda"
	exit
fi

if (( $UID != 0 )); then
	echo "Script has to be invoked as root. Use 'sudo $@'"
	exit 1
fi

if [[ ! -b $1 ]]; then
	echo "$1 is no disk"
	exit 1
fi

smartctl -A $1 | awk -v "disk=$1" '/^241/ { print "TBW of " disk ": "($10 * 512) * 1.0e-12, "TB" } '

