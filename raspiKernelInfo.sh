#!/bin/bash
#######################################################################################################################
#
# 		Retrieve information about running kernel on a Raspberry
#
####################################################################################################
#
#    Copyright (c) 2023 framp at linux-tips-and-tricks dot de
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

function displayAndExec() {

    echo "--- $1"
    if grep -q "$" <<< "$1"; then
        eval $1
    else
        $1
    fi
    echo ""
}
# see https://github.com/RPi-Distro/pi-gen
declare -A STAGE_DESCRIPTION=( \
		["stage0"]="Bootstrap" \
		["stage1"]="Truly minimal system" \
		["stage2"]="Lite system" \
		["stage3"]="Desktop system" \
		["stage4"]="Normal Raspbian image" \
		["stage5"]="The Raspbian Full image" \
		)
function extractStageDescription() {
	local stage=""
	stage="$(grep "^Generated" /etc/rpi-issue)"
	stage="${stage##* }"			# retrieve last field

	if [[ "${STAGE_DESCRIPTION[$stage]+abc}" ]]; then
		echo "${STAGE_DESCRIPTION[$stage]}"
	else
		echo "Unknown stage"
	fi
}

if [[ $1 == "-f" ]] ; then
    displayAndExec "tail -4 /proc/cpuinfo"
else
    displayAndExec "tail -4 /proc/cpuinfo | grep -v \"^Serial\""
fi
displayAndExec "free --human |  grep -E '^Speicher:|Mem:' | cut -c -20"
[[ $1 == "-f" ]] && displayAndExec "ip --brief link | grep -v '^lo'"
displayAndExec "ip --brief address | grep -v '^lo'"

displayAndExec "grep PRETTY_NAME /etc/os-release"
if [[ -f /etc/rpi-issue ]]; then
	displayAndExec "cat /etc/rpi-issue"
	echo -e "--- Image stage description \n$(extractStageDescription)\n"
fi

[[ -f /boot/config.txt ]] && displayAndExec "grep arm_64bit /boot/config.txt"
displayAndExec "getconf LONG_BIT"
displayAndExec "dpkg --print-architecture"
displayAndExec "uname -a"

displayAndExec "sudo parted -l"
if [[ $1 == "-f" ]] ; then
    displayAndExec "lsblk -f"
else
    displayAndExec "lsblk -o NAME,FSTYPE,LABEL,FSAVAIL,FSUSE%,MOUNTPOINT"
fi

displayAndExec "echo \$XDG_SESSION_TYPE"
[[ -n $DESKTOP_SESSION ]] && displayAndExec "echo \$DESKTOP_SESSION"
