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
}

displayAndExec "uname -a"
displayAndExec "dpkg --print-architecture"
displayAndExec "getconf LONG_BIT"
displayAndExec "echo \$XDG_SESSION_TYPE"
[[ -f /boot/config.txt ]] && displayAndExec "grep arm_64bit /boot/config.txt"
