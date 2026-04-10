#!/bin/bash
#######################################################################################################################
#
#    Resolve hostname of a local IPv6 address in a local network
#
####################################################################################################
#
#    Copyright (c) 2026 framp at linux-tips-and-tricks dot de
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

MYSELF=${0##*/}
VERSION="0.1"
GITREPO="https://github.com/framps/raspberryTools"

function usage() {
    cat << EOF
$MYSELF $VERSION ($GITREPO)
    
Usage: $MYSELF IPv6Address [dnsserver]

EOF
}

if (( $# < 1 )); then
	usage
	exit
fi

ipv6="$1"

dns="${2:-192.168.0.1}"
hostname=$(dig -x "$ipv6" @$dns +short)
if [[ -z $hostname ]]; then
	echo "Hostname of $1 not found"
	exit 1
else
	echo "Hostname of $1 is ${hostname::-1}"
	exit 0
fi	
