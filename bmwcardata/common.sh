#!/bin/bash
#
# Proof of concept code to retrieve BMW car data
#
# Common definitions
#
# See https://bmw-cardata.bmwgroup.com/customer/public/api-documentation 
# See https://bmw-cardata.bmwgroup.com/customer/public/api-specification for API Doc with Swagger
#
#######################################################################################################################
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

set -euo pipefail

readonly CONFIG_FILE=".bmwConfig"
readonly TOKEN_FILE=".bmwToken"

function err() {
    local rc="$1"
    echo "??? Unexpected error occured with RC $rc"
    local i=0
    local FRAMES=${#BASH_LINENO[@]}
    for ((i = FRAMES - 2; i >= 0; i--)); do
        echo '  File' \""${BASH_SOURCE[i + 1]}"\", line ${BASH_LINENO[i]}, in "${FUNCNAME[i + 1]}"
        sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i + 1]}"
    done
    exit 42
}

function require() {
	
	if ! command -v $1 &>/dev/null; then
	    echo "??? $1 could not be found"
	    exit 42
	fi
}

function requireConfig() {
	
	if [[ ! -f $CONFIG_FILE ]]; then
		echo "CLIENT_ID=" > $CONFIG_FILE
		echo "VIN=" >> $CONFIG_FILE
		echo "$CONFIG_FILE created. Define CLIENT_ID and VIN and invoke script once more"
		exit 42
	else
		source $CONFIG_FILE
	fi
}

function requireBothConfigs() {
	
	requireConfig
	
	if [[ ! -f $TOKEN_FILE ]]; then
		echo "??? Missing $TOKEN_FILE"
		exit 42
	else
		source $TOKEN_FILE
	fi
}

trap 'err $?' ERR

require curl
require jq


