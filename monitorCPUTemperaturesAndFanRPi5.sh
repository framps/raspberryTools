#!/bin/bash

#######################################################################################################################
#
#    Monitor CPU temperature and fan speed of a RPi5 with an original active fan
#	 First parameter defines the monitor interval. Default is 3 seconds.
#	 All measurements are recorded in a log file
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
# 	 This script was inspired by a script written by DistroEx (https://forum-raspberrypi.de/user/66526-distroex/)
#
#######################################################################################################################

readonly MYSELF="$(basename "$0")"
readonly MYNAME=${MYSELF##*/}
readonly LOGFILE="${MYNAME/.sh/}.log"

DELAY=${1:-3} # first parm defines the delay if specified

[[ -f $LOGFILE ]] && rm $LOGFILE # make sure log is deleted an all future logs can be appended

echo -e "Time \t\tFan \tCPU \tPMIC \tFreq" | tee -a "$LOGFILE" 
while true; do
  FAN="$(</sys/devices/platform/cooling_fan/hwmon/*/fan1_input)"	
  CPU="$(vcgencmd measure_temp | cut -d "=" -f 2)"
  CPU="${CPU//\'C/}"
  PMIC="$(vcgencmd measure_temp pmic | cut -d "=" -f 2)" 
  PMIC="${PMIC//\'C/}"
  FREQ="$(vcgencmd measure_clock arm | cut -d "=" -f 2)" 
  FREQ="${FREQ::4}"
  TIME="$(date +%H:%M:%S)"
  echo -e "$TIME \t$FAN \t$CPU \t$PMIC\t$FREQ" | tee -a "$LOGFILE"
  sleep $DELAY 
done
