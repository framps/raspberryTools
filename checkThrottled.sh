#!/bin/bash
#
#######################################################################################################################
#
# Retrieve throttling bits of Raspberry and report their semantic
#
# Throttle bit semantic according https://www.raspberrypi.com/documentation/computers/os.html and check for undervoltage
#
#######################################################################################################################
#
#    Copyright (c) 2019-2023 framp at linux-tips-and-tricks dot de
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

MYSELF="$(basename "$0")"
VERSION="0.2"
GITREPO="https://github.com/framps/raspberryTools"

echo "$MYSELF $VERSION ($GITREPO)"

# Bits         0                       1                     2                       3
m=("Under-voltage detected" "Arm frequency capped" "Currently throttled" "Soft temperature limit active"
    "" "" "" "" "" "" "" "" "" "" "" ""
    "Under-voltage has occurred" "Arm frequency capped has occurred" "Throttling has occurred" "Soft temperature limit has occurred")
# Bits      16                            17                              18                              19
d=("Power supply dipped below 4.63 V" "CPU speed limited due to temperature" "Performance reduced due to temperature or power" "CPU temperature near limit (default ~60°C)"
    "" "" "" "" "" "" "" "" "" "" "" ""
    "Power supply dipped below 4.63 V" "CPU speed limited due to temperature" "Performance reduced due to temperature or power" "CPU temperature near limit (default ~60°C)" )
# Bits      16                            17                              18                              19

function analyze() { 

    local i=0                                                    # start with bit 0 (LSb)
    local t=$(vcgencmd get_throttled $o | cut -f 2 -d "=")
    local b=$(perl -e "printf \"%020b\\n\", $t" 2> /dev/null) # convert hex number into binary number

    while [[ -n $b ]]; do                                       # there are still bits to process
	if (( $i == 0 )); then
		echo "- Current issues"
	elif (( $i == 16 )); then
		echo "- Previous detected issues"
	fi
        t=${b:${#b}-1:1}                                         # extract LSb
        if (( $t != 0 )); then                                     # bit set ?
            if (( $i <= ${#m[@]} - 1 )) && [[ -n ${m[$i]} ]]; then # bit meaning is defined
	        echo "Bit $i: ${m[$i]} (${d[$i]})"
            else # bit meaning unknown
                echo "Bit $i: meaning unknown"               # undefined bit
            fi
        fi
        b=${b::-1} # remove LSb from throttle bits
        ((i++))    # inc bit counter
    done
}

if ! $which vcgencmd &> /dev/null; then
    echo "No vcgencmd detected."
    exit 42
fi

analyze 
