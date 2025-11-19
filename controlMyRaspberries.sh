#!/bin/bash
#######################################################################################################################
#
# 	 Start up and shut down Raspberry servers connected to a Tasmota power switch
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


readonly VERSION="0.2"
readonly GITREPO="https://github.com/framps/raspberryTools"

readonly MYSELF="$(basename "$0")"
readonly MYNAME=${MYSELF##*/}

readonly SWITCH="192.168.0.155"						 	# Tasmota switch to turn off and on Raspberries

readonly SERVERS=( pi@192.168.0.194 pi@192.168.0.158 )	# Raspberries powered via a Tasmota power switch

function isOnline() { # ip
	ping -c1 -w3 $1 &>/dev/null
	return
}

function turnOff() { # ip
	curl http://$1/cm?cmnd=Power%20Off &>/dev/null
}

function turnOn() { # ip
	curl http://$1/cm?cmnd=Power%20On &>/dev/null
}

function powerStatus() { # ip
	local state=$(curl -s http://$1/cm?cmnd=Status | jq .[].Power)
	echo "$state"
}

echo "$MYSELF $VERSION ($GITREPO)"

if [[ $1 == "off" ]]; then

	for user in "${SERVERS[@]}"; do
		ip="$(cut -f 2 -d "@" <<< "$user")"
		if isOnline $ip; then
			echo -n "Shutting down $ip ... "
			ssh $user "sudo shutdown -h now" &>/dev/null
			while $(isOnline $ip); do
				sleep 3
			done
			echo "done"
		else
			echo "$ip already offline"
		fi
	done

	# now turn off power supply

	status="$(powerStatus $SWITCH)"
	if (( $status != 0 )); then
		echo -n "Turning off $SWITCH ... "
		turnOff $SWITCH
		while (( $(powerStatus $SWITCH) != 0 )); do
			sleep 3
		done
		echo "done"
	else
		echo "$SWITCH already off"
	fi

elif [[ $1 == "on" ]]; then

	status="$(powerStatus $SWITCH)"
	if (( $status == 0 )); then
		echo -n "Turning on $SWITCH ... "
		turnOn $SWITCH
		while (( $(powerStatus $SWITCH) == 0 )); do
			sleep 3
		done
		echo "done"
	else
		echo "$SWITCH already on"
	fi
else
	echo "Missing command \"on\" or \"off\""
fi
