#!/bin/bash
#
# Small script which extracts lifetime writes (LTW) (kB)
# from one ext2/3/4 partition or all existing ext2/3/4 partitions on a system
#
# Copyright (C) 2019 framp at linux-tips-and-tricks dot de

me=$(basename "$0")

if (( $UID != 0 )); then
	echo "Script has to be invoked as root. Use 'sudo $@'"
	exit 1
fi

if (( $# == 0 || $# > 1 )); then
	echo "Purpose: Retrieve lifetime writes (kB) of ext2/3/4 disks"
	echo "Syntax:  'sudo $me -a' to retrieve LTW of all existing ext disks"
	echo "         'sudo $me <disk>' to retrieve LTW of passed ext disk"
	echo "Example: 'sudo $me /dev/sda' or 'sudo $me -a'"
	exit 1
fi

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

function echoLTW() { # disk
	part=${1#"/dev/"}
	if [[ -e /sys/fs/ext4/$part/lifetime_write_kbytes ]]; then
		size=$(( $(cat /sys/fs/ext4/$part/lifetime_write_kbytes) * 1024 ))
		echo "$1 $(bytesToHuman $size)"
	fi
}

if [[ $1 == "-a" ]]; then
	blkid | awk '/TYPE="ext/ { print $1; }; ' | while read disk; do
		part=${disk::-1}
		echoLTW "$part"
	done
else
	if [[ ! -b $1 ]]; then
		echo "$1 is no disk"
		exit 1
	fi
	echoLTW "$1"
fi

