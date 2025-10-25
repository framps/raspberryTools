#!/bin/bash
#######################################################################################################################
#
#   Find all existing Raspberries or ESPs in local subnet
#
#   Search for mac addresses used by Raspberries which are defined on
#   https://udger.com/resources/mac-address-vendor-detail?name=raspberry_pi_foundation
#   or ESPs
#   https://udger.com/resources/mac-address-vendor-detail?name=espressif_inc
#
#######################################################################################################################
#
#    Copyright (c) 2025 framp at linux-tips-and-tricks dot de
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

VERSION=0.1
GITREPO="https://github.com/framps/raspberryTools"

MYSELF="$(basename "$0")"
MYNAME=${MYSELF%.*}
S_OPTIONARGS="imhd"

declare -r PS4='|${LINENO}> \011${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# check for required commands and required bash version

if ! command -v nmap COMMAND &> /dev/null; then
    echo "Missing required program nmap."
    exit 255
fi

if ! command -v host COMMAND &> /dev/null; then
    echo "Missing required program host."
    exit 255
fi

if ((BASH_VERSINFO[0] < 4)); then
    echo "Minimum bash 4.0 is required. You have $BASH_VERSION."
    exit 255
fi

# define defaults

readonly INI_FILENAME=/usr/local/etc/${MYNAME}.conf
readonly DEFAULT_SUBNETMASK="192.168.0.0/24"
readonly DEFAULT_DEVICE="r"
readonly RASPBERRY="r"
readonly ESP="e"

declare -A DEVICE_NAME=(
    [$RASPBERRY]="Raspberries"
    [$ESP]="ESPs"
)

# See https://www.ipchecktool.com/tool/macfinder for MACs
# see https://udger.com/resources/mac-address-vendor-detail?name=raspberry_pi_foundation
# see https://udger.com/resources/mac-address-vendor-detail?name=espressif_inc
declare -A DEFAULT_MAC_REGEX=(
    [$RASPBERRY]="28:cd:c1|2c:cf:67|b8:27:eb|d8:3a:dd|dc:a6:32|e4:5f:01"
    [$ESP]="10:52:1C|24:62:AB|24:6f:28|24:A1:60|3C:61:05|3C:71:BF|48:3F:DA|A4:CF:12|BC:DD:C2|CC:50:E3|E0:98:06|E8:DB:84|EC:64:C9|F4:CF:A2|FC:F5:C4"
)
# help text

function usage() {
    cat << EOH
$MYSELF $VERSION ($GITREPO)

Usage:
    $MYSELF                       Scan subnet $DEFAULT_SUBNETMASK for Raspberries or ESPs sorted by IP
    $MYSELF -n <subnetmask>       Scan subnet for Raspberries
    $MYSELF -d [e|r]              Devices to search for, either Raspberries ($RASPBERRY) or ESPs ($ESP) (Default: $RASPBERRY)
    $MYSELF -s [i|m|h|d]          Sort for IPs, Macs, Hostnames or description, Default: IP
    $MYSELF -h | -? | --help      Show this help text 

Defaults:
    Subnetmask: $DEFAULT_SUBNETMASK
    Mac regex for Raspberries: ${DEFAULT_MAC_REGEX[$RASPBERRY]}
    Mac regex for ESPs: ${DEFAULT_MAC_REGEX[$ESP]}
    Initfilename: /usr/local/etc/${MYNAME}.conf

Example:
    $MYSELF -n 192.168.179.0/24 -s m

Init file can be used to customize the mac address scan and descriptions.
First optional line can be the regex for the macs to scan. See default below for an example.
All following lines can contain a mac and a description separated by a space to add a meaningful
description to the system which owns this mac. Otherwise the hostname discovered will used as the description.

Example file contents for init file:
    rm b8:27:eb|dc:a6:32|e4:5f:01
    rd b8:27:eb:b8:27:eb VPN Server
    rd b8:27:eb:b8:28:eb Web Server
    em 10:52:1C|24:62:AB|24:6f:28
    ed 10:52:1C:24:62:AB PiHole
    ed 10:52:1C:24:62:AC Docker 
EOH
}

tmp=""

function cleanup() {
    if [[ -f "$tmp" ]]; then
        rm "$tmp" &> /dev/null
    fi
}

function err() {
    echo "??? Unexpected error occured"
    local i=0
    local FRAMES=${#BASH_LINENO[@]}
    for ((i = FRAMES - 2; i >= 0; i--)); do
        echo '  File' \""${BASH_SOURCE[i + 1]}\"", line ${BASH_LINENO[i]}, in "${FUNCNAME[i + 1]}"
        sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i + 1]}"
    done
    exit
}

trap 'cleanup' SIGINT SIGTERM SIGHUP EXIT
trap 'err' ERR

sortType=""
device=""
network=""

while getopts ":h :n: :d: :s:" opt; do
    case "$opt" in
        h)
            usage
            exit 0
            ;;
        n)
            network=${OPTARG}
            ;;
        d)
            device=${OPTARG}
            if [[ ! "$device" =~ [e|r] ]]; then
                echo "Unknown parameter $OPTARG for option -d"
                exit 1
            fi
            ;;
        s)
            sortType=${OPTARG}
            if [[ ! "$sortType" =~ [i|m|h|d] ]]; then
                echo "Unknown parameter $OPTARG for option -"
                exit 1
            fi
            ;;
        \?)
            echo "Unknown option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Missing option argument for -$OPTARG" >&2
            exit 1
            ;;
        *)
            echo "Unimplemented option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

: "${sortType:=i}"
: "${network:=$DEFAULT_SUBNETMASK}"
: "${device:=$DEFAULT_DEVICE}"
deviceName="${DEVICE_NAME[$device]}"
MY_MAC_REGEX="${DEFAULT_MAC_REGEX[$device]}"

# read property file with mac regexes

if [[ -f "$INI_FILENAME" ]]; then
    if MY_MAC_REGEX_FROM_INI="$(grep -E "^${device}m" "$INI_FILENAME" | awk '{print $2}')"; then
        MY_MAC_REGEX="$MY_MAC_REGEX_FROM_INI"
    fi
fi
MY_MAC_REGEX=" (${MY_MAC_REGEX})"

# define associative arrays for mac and hostname lookups

declare -A macAddress=()

echo "$MYSELF $VERSION ($GITREPO)"
echo "Scanning subnet $network for $deviceName ..."

# scan subnet for Raspberry macs

# 192.168.0.12             ether   dc:a6:32:8f:28:fd   C                     wlp3s0 -
while read -r ip dummy mac rest; do
    macAddress["$ip"]="$mac"
done < <(
    nmap -sP "$network" &> /dev/null
    arp -n | grep -Ei " $MY_MAC_REGEX"
)

tmp=$(mktemp)

# retrieve and print hostnames

if ((${#macAddress[@]} > 0)); then

    maxHostnameLen=0
    maxDescriptionLen=0

    for ip in "${!macAddress[@]}"; do
        host=""
        if h="$(host "$ip")"; then
            #shellcheck disable=SC2034
            # (warning): arpa appears unused. Verify use (or export if used externally).
            read -r arpa dummy dummy dummy host rest <<< "$h"
            host=${host::-1} # delete trailing "."
        else
            :
        fi
        if [[ -z "$host" ]]; then
            host="Unknown"
        fi

        if [[ -f "$INI_FILENAME" ]]; then
            if hostDescription="$(grep -E -i "^${device}d ${macAddress[$ip]}" "$INI_FILENAME")"; then
                hostDescription="$(cut -f 3- -d ' ' <<< "$hostDescription" | sed 's/^ *//; s/ *$//')"
            fi
        fi

        : "${hostDescription:="n/a"}"

        ((maxHostnameLen < ${#host})) && maxHostnameLen=${#host}
        ((maxDescriptionLen < ${#hostDescription})) && maxDescriptionLen=${#hostDescription}

        printf "%s %s %s %s\n" "$ip" "${macAddress[$ip]}" "$host" "$hostDescription" >> "$tmp"
    done

    printf "\n%-15s %-17s %-${maxHostnameLen}s %-${maxDescriptionLen}s\n" "IP address" "Mac address" "Hostname" "Description"

    sort=$(cut -f 2 -d " " <<< "$sortType")
    if [[ $sort == "i" ]]; then
        sortCmd="sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n"
    else
        key=$(grep -aob "$sort" <<< "$S_OPTIONARGS" | grep -oE '[0-9]+')
        ((key++))
        sortCmd="sort -k $key"
    fi

    while read -r ip mac host desc; do
        printf "%-15s %-17s %-${maxHostnameLen}s %-${maxDescriptionLen}s\n" "$ip" "$mac" "$host" "$desc"
    done < <($sortCmd "$tmp")

else
    echo "No $deviceName found with mac regex $MY_MAC_REGEX"
fi
