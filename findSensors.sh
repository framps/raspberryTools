#!/bin/bash

#######################################################################################################################
#
# 	 Find all ESP sensors in local network
#
#######################################################################################################################
#
#    Copyright (c) 2021-2024 framp at linux-tips-and-tricks dot de
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

set -euo pipefail

VERSION=0.6
MYSELF="$(basename "$0")"
MYNAME=${MYSELF%.*}

# check for required commands and required bash version

if ! command -v nmap COMMAND &> /dev/null; then
	echo "Missing required program nmap."
	exit 255
fi

if ! command -v host COMMAND &> /dev/null; then
	echo "Missing required program host."
	exit 255
fi

if (( BASH_VERSINFO[0] < 4 )); then
	echo "Minimum bash 4.0 is required. You have $BASH_VERSION."
	exit 255
fi

# define defaults

DEFAULT_SUBNETMASK="192.168.0.0/24"
DEFAULT_MAC_REGEX="10:52:1C|24:62:AB|24:6f:28|24:A1:60|3C:61:05|3C:71:BF|48:3F:DA|A4:CF:12|BC:DD:C2|CC:50:E3|E0:98:06|E8:DB:84|F4:CF:A2|FC:F5:C4"
INI_FILENAME=$HOME/.${MYNAME}

# help text

if (( $# >= 1 )) && [[ "$1" =~ ^(-h|--help|-\?)$ ]]; then
	cat << EOH
	$MYSELF $VERSION
Usage:
	$MYSELF                       Scan subnet $DEFAULT_SUBNETMASK for ESPs
	$MYSELF <subnetmask>          Scan subnet for ESPs
	$MYSELF -h | -? | --help      Show this help text

Defaults:
	Subnetmask: $DEFAULT_SUBNETMASK
	Mac regex:  $DEFAULT_MAC_REGEX

Example:
	$MYSELF 192.168.179.0/24

Init file $INI_FILENAME can be used to customize the mac address scan and descriptions.
First optional line can be the regex for the macs to scan. See default above for an example.
All following lines can contain a mac and a description separated by a space to add a meaningful
description to the system which owns this mac. Otherwise the hostname discovered will used as the description.

	Example file contents for $INI_FILENAME:
b8:27:eb|dc:a6:32|e4:5f:01
b8:27:eb:b8:27:eb VPN Server
b8:27:eb:b8:28:eb Web Server

EOH
	exit 0
fi

# read options

MY_NETWORK=${1:-$DEFAULT_SUBNETMASK}

# read property file with mac regexes

MY_MAC_REGEX="$DEFAULT_MAC_REGEX"

if [[ -f "$INI_FILENAME" ]]; then
	MY_MAC_REGEX_FROM_INI="$(head -n 1 "$INI_FILENAME" | cut -f 2 -d " ")"
	if [[ -z "$MY_MAC_REGEX_FROM_INI" ]]; then
		echo "Using Mac Regex from $INI_FILENAME"
		MY_MAC_REGEX="$(head -n 1 "$INI_FILENAME")"
	fi
fi
MY_MAC_REGEX=" (${MY_MAC_REGEX})"

# define associative arrays for mac and hostname lookups

declare -A macAddress=()

echo "Scanning subnet $MY_NETWORK for ESPs ..."

# scan subnet for ESP macs

# 192.168.0.12             ether   dc:a6:32:8f:28:fd   C                     wlp3s0 -
while read -r ip dummy mac rest; do
	macAddress["$ip"]="$mac"
done < <(nmap -sP "$MY_NETWORK" &>/dev/null; arp -n | grep -Ei " $MY_MAC_REGEX")

# retrieve and print hostnames

if (( ${#macAddress[@]} > 0 )); then

	printf "\n%-15s %-17s %s\n" "IP address" "Mac address" "Hostname (Description)"

	IFS=$'\n'
	sorted=($(sort -t . -k 3,3n -k 4,4n <<< "${!macAddress[*]}"))
	unset IFS

	for ip in "${sorted[@]}"; do
		set +e
		h="$(host "$ip")"
		rc=$?
		set -e
		host=""
		if (( ! rc )); then
			# 12.0.168.192.in-addr.arpa domain name pointer asterix.
			read -r arpa dummy dummy dummy host rest <<< "$h"
			: "$arpa" "$dummy" # suppress shellcheck warning
			host=${host::-1} # delete trailing "."
		fi

		if [[ -z "$host" ]]; then
			host="Unknown"
		fi

		if [[ -f "$INI_FILENAME" ]]; then
			set +e
			hostDescription="$(grep "${macAddress[$ip]}" "$INI_FILENAME")"
			rc=$?
			set -e
			if (( ! rc )); then
				hostDescription="$(cut -f 2- -d ' ' <<< "$hostDescription" | sed 's/^ *//; s/ *$//')"
				host="${host} ($hostDescription)"
			fi
		fi

		printf "%-15s %17s %s\n" "$ip" "${macAddress[$ip]}" "$host"
	done
else
	echo "No ESPs found with mac regex $MY_MAC_REGEX"
fi
