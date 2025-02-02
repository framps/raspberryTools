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

VERSION=0.7.2
GITREPO="https://github.com/framps/raspberryTools"

MYSELF="$(basename "$0")"
MYNAME=${MYSELF%.*}
S_OPTIONARGS="imhd"

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

# See https://www.ipchecktool.com/tool/macfinder for MACs

DEFAULT_SUBNETMASK="192.168.0.0/24"
DEFAULT_MAC_REGEX="10:52:1C|24:62:AB|24:6f:28|24:A1:60|3C:61:05|3C:71:BF|48:3F:DA|A4:CF:12|BC:DD:C2|CC:50:E3|E0:98:06|E8:DB:84|EC:64:C9|F4:CF:A2|FC:F5:C4"
INI_FILENAME=/usr/local/etc/${MYNAME}.conf

# help text

if (( $# >= 1 )) && [[ "$1" =~ ^(-h|--help|-\?)$ ]]; then
	cat << EOH
	$MYSELF $VERSION ($GITREPO)
Usage:
	$MYSELF                       Scan subnet $DEFAULT_SUBNETMASK for ESPs sorted by IPs
	$MYSELF -n <subnetmask>       Scan subnet for ESPs
	$MYSELF -s [i|m|h|d]          Sort for IPs, Macs, Hostnames or description, Default: IP
	$MYSELF -h | -? | --help      Show this help text

Defaults:
	Subnetmask: $DEFAULT_SUBNETMASK
	Mac regex:  $DEFAULT_MAC_REGEX

Example:
	$MYSELF -n 192.168.179.0/24 -s m

Init file $INI_FILENAME can be used to customize the mac address scan and descriptions.
First optional line can be the regex for the macs to scan. See default below for an example.
All following lines can contain a mac and a description separated by a space to add a meaningful
description to the system which owns this mac. Otherwise the hostname discovered will used as the description.

	Example file contents for $INI_FILENAME:
b8:27:eb|dc:a6:32|e4:5f:01
b8:27:eb:b8:27:eb VPN Server
b8:27:eb:b8:28:eb Web Server

EOH
	exit 0
fi

set +e
sortType="$(grep -o "\-s [$S_OPTIONARGS]" <<< "$@")"
set -e
[[ -z $sortType ]] && sortType="-s i"

set +e
network="$(grep -E -o '\-n \S+' <<< "$@")"
set -e
if [[ -z $network ]]; then
	network="$DEFAULT_SUBNETMASK"
else
	network=$(cut -f2 -d" " <<< "$network")
fi

# read property file with mac regexes

MY_MAC_REGEX="$DEFAULT_MAC_REGEX"

if [[ -f "$INI_FILENAME" ]]; then
	MY_MAC_REGEX_FROM_INI="$(head -n 1 "$INI_FILENAME" | awk '{print $2}')"
	if [[ -z "$MY_MAC_REGEX_FROM_INI" ]]; then
		MY_MAC_REGEX="$(head -n 1 "$INI_FILENAME")"
	fi
fi
MY_MAC_REGEX=" (${MY_MAC_REGEX})"

# define associative arrays for mac and hostname lookups

declare -A macAddress=()

echo "$MYSELF $VERSION ($GITREPO)"
echo "Scanning subnet $network for ESPs ..."

echo "Note: $MYSELF is deprecated. Use findDevies instead"

# scan subnet for ESP macs

# 192.168.0.12             ether   dc:a6:32:8f:28:fd   C                     wlp3s0 -
while read -r ip dummy mac rest; do
	macAddress["$ip"]="$mac"
done < <(nmap -sP "$network" &>/dev/null; arp -n | grep -Ei " $MY_MAC_REGEX")

tmp=$(mktemp)

# retrieve and print hostnames

if (( ${#macAddress[@]} > 0 )); then

	maxHostnameLen=0
	maxDescriptionLen=0

	for ip in "${!macAddress[@]}"; do
		set +e
		h="$(host "$ip")"
		rc=$?
		set -e
		host=""
		if (( ! rc )); then
			# 12.0.168.192.in-addr.arpa domain name pointer asterix.
			#shellcheck disable=SC2034
            #(warning): arpa appears unused. Verify use (or export if used externally).
			read -r arpa dummy dummy dummy host rest <<< "$h"
			host=${host::-1} # delete trailing "."
		fi

		if [[ -z "$host" ]]; then
			host="Unknown"
		fi

		if [[ -f "$INI_FILENAME" ]]; then
			set +e
			hostDescription="$(grep -i "${macAddress[$ip]}" "$INI_FILENAME")"
			rc=$?
			set -e
			if (( ! rc )); then
				hostDescription="$(cut -f 2- -d ' ' <<< "$hostDescription" | sed 's/^ *//; s/ *$//')"
			else
				hostDescription=""
			fi
		else
			hostDescription="n/a"
		fi

		(( maxHostnameLen < ${#host} )) && maxHostnameLen=${#host}
		(( maxDescriptionLen < ${#hostDescription} )) && maxDescriptionLen=${#hostDescription}

		printf "%s %s %s %s\n" "$ip" "${macAddress[$ip]}" "$host" "$hostDescription" >> "$tmp"
	done

	printf "\n%-15s %-17s %-${maxHostnameLen}s %-${maxDescriptionLen}s\n" "IP address" "Mac address" "Hostname" "Description"	

	sort=$(cut -f 2 -d " " <<< "$sortType")
	if [[ $sort == "i" ]]; then
		sortCmd="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n"
	else
		key=$(grep -aob "$sort" <<< "$S_OPTIONARGS"| grep -oE '[0-9]+')
		((key++))
		sortCmd="sort -k $key"
	fi

	while read -r ip mac host desc ; do
		printf "%-15s %-17s %-${maxHostnameLen}s %-${maxDescriptionLen}s\n" "$ip" "$mac" "$host" "$desc"
	done < <($sortCmd "$tmp")

else
	echo "No ESPs found with mac regex $MY_MAC_REGEX"
fi

rm "$tmp"
