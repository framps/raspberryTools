#!/bin/bash

#   Find all existing Raspberries in local subnet
#
#   Copyright (C) 2020 framp at linux-tips-and-tricks dot de
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

VERSION=0.2
MYSELF="$(basename "$0")"

DEFAULT_SUBNETMASK="192.168.0.0/24"

if [[ "$1" =~ ^(-h|--help|-\?)$ ]]; then
	cat << EOH
Usage:
	$MYSELF                       Scan subnet $DEFAULT_SUBNETMASK for Raspberries
	$MYSELF <subnetmask>          Scan subnet for Raspberries
	$MYSELF -h | -? | --help      Show this help text
	
Defaults:	
	Subnetmask: $DEFAULT_SUBNETMASK
	
Example:	
	$MYSELF 192.168.179.0/24
	
EOH
	exit 0
fi

MY_NETWORK=${1:-$DEFAULT_SUBNETMASK}    

echo "Scanning subnet $MY_NETWORK for Raspberries..."

declare -A macAddress=()
declare -A hostName=()

# 192.168.0.12             ether   dc:a6:32:8f:28:fd   C                     wlp3s0 - 
while read ip dummy mac rest; do
	macAddress["$ip"]="$mac"
done < <(nmap -sP $MY_NETWORK &>/dev/null; arp -n | grep -E " (b8:27:eb|dc:a6:32|e4:5f:01)")

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
