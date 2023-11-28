#!/bin/bash
#######################################################################################################################
#
#    Retrieve information about running kernel on a Raspberry
#
#    Call with 
#    curl -s https://raw.githubusercontent.com/rpi-simonz/raspberryTools/master/raspiKernelInfo.sh | bash
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

MYSELF=${0##*/}

function usage() {
    cat <<EOF
Usage: $MYSELF [option]*

-Options-
-c  show the command producing the info, additionally to the short description
-C  show the command producing the info, without short description
-f  show full (more) infos about the system
EOF
}

function displayAndExec() {

    if (( $ONLYCOMMANDS )) ; then
        echo "--- $1"
    else
        if (( $COMMANDS )) ; then
            echo "--- ${2:+$2 ---} $1"
        else
            echo "--- ${2:-$1}"
        fi
    fi

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

COMMANDS=0
ONLYCOMMANDS=0
FULL=0

while (( "$#" )); do

  case "$1" in
      -c|--commands)
          COMMANDS=1 ; shift 1
          ;;
      -C|--onlycommands)
          ONLYCOMMANDS=1 ; shift 1
          ;;
      -f|--full)
          FULL=1 ; shift 1
          ;;
      -h|--help)
          usage ; exit
          ;;
  esac
done


if (( $FULL )) ; then
    displayAndExec "tail -4 /proc/cpuinfo"  "CPUINFO"
else
    displayAndExec "tail -4 /proc/cpuinfo | grep -v \"^Serial\""  "CPUINFO"
fi

displayAndExec "free --human |  grep -E '^Speicher:|Mem:' | cut -c -20"  "MEMORY"

(( $FULL )) && displayAndExec "(ip --brief link ; ip --brief address) | grep -v '^lo'"  "NETWORK"

displayAndExec "grep PRETTY_NAME /etc/os-release"  "OS"
if [[ -f /etc/rpi-issue ]]; then
	displayAndExec "cat /etc/rpi-issue ; echo -e \"($(extractStageDescription))\""  "ORIGINAL IMAGE"
fi

[[ -f /boot/config.txt ]] && displayAndExec "grep arm_64bit /boot/config.txt"  "64 BIT SET IN CONFIG?"
displayAndExec "getconf LONG_BIT"  "SOFTWARE BITS"
displayAndExec "dpkg --print-architecture"  "SOFTWARE ARCH"
displayAndExec "uname -a"  "SYSTEM INFORMATION"

(( $FULL )) && displayAndExec "sudo parted -l | grep -v -e '^Sector' -e '^Partition' -e '^$' -e '^Disk Flags'"  "STORAGE"
(( $FULL )) && displayAndExec "lsblk -f"  "STORAGE"

displayAndExec "echo \$XDG_SESSION_TYPE"  "X11, WAYLAND OR TTY"
[[ -n $DESKTOP_SESSION ]] && displayAndExec "echo \$DESKTOP_SESSION"
