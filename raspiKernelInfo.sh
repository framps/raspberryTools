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
#	  Note: This code reuses some code from raspi-config (See https://github.com/RPi-Distro/raspi-config/blob/bookworm/raspi-config)
#
#######################################################################################################################

is_pi () {
  ARCH=$(dpkg --print-architecture)
  if [ "$ARCH" = "armhf" ] || [ "$ARCH" = "arm64" ] ; then
    return 0
  else
    return 1
  fi
}

# tests for Pi 1, 2 and 0 all test for specific boards...

is_pione() {
  if grep -q "^Revision\s*:\s*00[0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo; then
    return 0
  elif grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[0-36][0-9a-fA-F]$" /proc/cpuinfo ; then
    return 0
  else
    return 1
  fi
}

is_pitwo() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]04[0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

is_pizero() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]0[9cC][0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

# ...while tests for Pi 3 and 4 just test processor type, so will also find CM3, CM4, Zero 2 etc.

is_pithree() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F]2[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

is_pifour() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F]3[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

is_pifive() {
  grep -q "^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F]4[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$" /proc/cpuinfo
  return $?
}

get_pi_type() {
  if is_pione; then
    echo 1
  elif is_pitwo; then
    echo 2
  elif is_pithree; then
    echo 3
  elif is_pifour; then
    echo 4
  elif is_pifive; then
    echo 5
  elif is_pizero; then
    echo 0
  else
    echo -1
  fi
}

function displayAndExec() {

    echo "--- $1"
    if grep -q "$" <<< "$1"; then
        eval $1
    else
        $1
    fi
}

if is_pi; then
	echo "--- RPi HW version $(get_pi_type) detected"

	displayAndExec "uname -a"
	displayAndExec "dpkg --print-architecture"
	displayAndExec "getconf LONG_BIT"
	displayAndExec "echo \$XDG_SESSION_TYPE"
	[[ -f /boot/config.txt ]] && displayAndExec "grep arm_64bit /boot/config.txt"
	[[ -f /etc/rpi-issue ]] && displayAndExec "cat /etc/rpi-issue"
	displayAndExec "tail -4 /proc/cpuinfo | grep -v \"^Serial\""
else
	echo "No RaspberryPi detected"
fi
