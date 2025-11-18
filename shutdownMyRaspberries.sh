#!/bin/bash
#######################################################################################################################
#
# 	 Shut down Raspberry servers connected to a Tasmota power switch and turn off power supply
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


readonly VERSION="0.1"
readonly GITREPO="https://github.com/framps/raspberryTools"

readonly MYSELF="$(basename "$0")"
readonly MYNAME=${MYSELF##*/}

readonly SWITCH="192.168.0.155"						# Tasmota switch to turn off Raspberries

readonly SERVERS=( 192.168.0.194 192.168.0.158 )	# Raspberries connected to Tasmota switch

function isOnline() { # ip
	ping -c1 -w3 $1 &>/dev/null
	return
}

function shutdown() { # ip 
	curl http://$1/cm?cmnd=Power%20Off &>/dev/null
	echo -n "Initiated shut down of $ip ... "
}

echo "$MYSELF $VERSION ($GITREPO)"

# shutdown servers and wait until they are offline

for ip in "${SERVERS[@]}"; do
	if isOnline $ip; then
		echo -n "Shutting down $ip ... "
		ssh $ip "sudo shutdown -h now" &>/dev/null
		while $(isOnline $ip); do
			sleep 3
		done
		echo "done"
	else
		echo "$ip already offline"	
	fi	
done	

# now turn off power supply

shutdown $SWITCH
echo "done"
