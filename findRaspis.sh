#!/bin/bash

#   Find all existing Raspberries in local subnet
#
#   Copyright (C) 2021 framp at linux-tips-and-tricks dot de
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

VERSION=0.3
MYSELF="$(basename "$0")"
MYNAME=${MYSELF%.*}

set -euo pipefail

if ! command -v nmap COMMAND &> /dev/null; then
	printf "\n\033[1;35m Missing required program nmap.\033[m\n\n"  >&2 
	exit 255
fi

if ! command -v host COMMAND &> /dev/null; then
	printf "\n\033[1;35m Missing required program host.\033[m\n\n"  >&2 
	exit 255
fi

if (( ${BASH_VERSINFO[0]} < 4 )); then
	printf "\n\033[1;35m Minimum requirement is bash 4.0. You have $BASH_VERSION \033[m\n\n"  >&2 
	exit 255
fi

DEFAULT_SUBNETMASK="192.168.0.0/24"
DEFAULT_MAC_REGEX="b8:27:eb|dc:a6:32|e4:5f:01"
INI_FILENAME="./.${MYNAME}"

if [[ "$1" =~ ^(-h|--help|-\?)$ ]]; then
	cat << EOH
Usage:
	$MYSELF                       Scan subnet $DEFAULT_SUBNETMASK for Raspberries
	$MYSELF <subnetmask>          Scan subnet for Raspberries
	$MYSELF -h | -? | --help      Show this help text
	
Defaults:	
	Subnetmask: $DEFAULT_SUBNETMASK
	Mac regex:  $DEFAULT_MAC_REGEX
	
Example:	
	$MYSELF 192.168.179.0/24
	
Init file $INI_FILENAME can be used to customize the Mac Regex. Every line has to define a Mac Regex

	Example file contents for $INI_FILENAME:	
b8:27:eb
dc:a6:32
e4:5f:01
	
EOH
	exit 0
fi

MY_NETWORK=${1:-$DEFAULT_SUBNETMASK}    

if [[ ! -f $INI_FILENAME ]]; then
	MY_MAC_REGEX="$DEFAULT_MAC_REGEX"
else
	echo "Using Mac Regex from $INI_FILENAME"
	MY_MAC_REGEX=""
	while read line; do 
		if [[ -n $MY_MAC_REGEX ]]; then
			MY_MAC_REGEX="$MY_MAC_REGEX|"
		fi
		MY_MAC_REGEX="$MY_MAC_REGEX$line"
	done < $INI_FILENAME
fi	
MY_MAC_REGEX=" (${MY_MAC_REGEX})"

echo "Scanning subnet $MY_NETWORK for Raspberries using Regex$MY_MAC_REGEX ..."

declare -A macAddress=()
declare -A hostName=()

# 192.168.0.12             ether   dc:a6:32:8f:28:fd   C                     wlp3s0 - 
while read ip dummy mac rest; do
	macAddress["$ip"]="$mac"
done < <(nmap -sP $MY_NETWORK &>/dev/null; arp -n | grep -E " $MY_MAC_REGEX")

echo "${#macAddress[@]} Raspberries found"

if (( ${#macAddress[@]} > 0 )); then
	echo "Retrieving hostnames ..."

	printf "%-15s %-17s %s\n" "IP address" "Mac address" "Hostname"

	# 12.0.168.192.in-addr.arpa domain name pointer asterix.
	for ip in "${!macAddress[@]}"; do
		h="$(host "$ip")"
		if (( ! $? )); then
			read arpa dummy dummy dummy host rest <<< "$h"
			host=${host::-1} # delete trailing "."
		else
			host="-Unknown-"
		fi
		printf "%-15s %17s %s\n" $ip ${macAddress[$ip]} $host
	done 
fi
