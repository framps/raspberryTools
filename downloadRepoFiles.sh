#!/bin/bash
#######################################################################################################################
#
#  Convenient script to download raspberryTools to evaluate them and optionally to install them
#
#######################################################################################################################
#
#    Copyright (c) 2024 framp at linux-tips-and-tricks dot de
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

readonly GITAPI_RESTURL_TREES="https://api.github.com/repos/framps/raspberryTools/git/trees/master?recursive=1"
readonly GIT_DOWNLOAD_PREFIX="https://raw.githubusercontent.com/framps/raspberryTools/master"
readonly INSTALL_DIR="/usr/local/bin"

MYSELF="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"					# use linked script name if the link is used
MYNAME=${MYSELF%.*}

if (( $# > 1 )) && [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-?" || "$1" == "?" ]]; then
	echo "Purpose: Download any files from raspberryTools github repository."
	echo "Syntax:  $MYSELF - Select files to download"
	echo "		   $MYSELF install - Select files to download and install in /usr/local/bin"
	exit 0
fi

if (( $# != 0 )); then
	if [[ $1 != "install" ]]; then
		echo "Unknown option "$1""
		exit 1
	fi
	fkt="$1"
else
	fkt=""
fi

if ! which jq &>/dev/null; then
	echo "... Installing jq required by $MYNAME."
	sudo apt install jq
	if ! which jq &>/dev/null; then
		echo "??? jq required by $MYNAME. Automatic jq installation failed. Please install jq manually."
		exit 1
	fi
fi

jsonFile=$(mktemp)

trap "rm -f $jsonFile" SIGINT SIGTERM EXIT

echo "--- Available raspberyTools ---"
TOKEN=""															# Personal token to get better rate limits
if [[ -n $TOKEN ]]; then
	HTTP_CODE="$(curl -sq -w "%{http_code}" -o $jsonFile -H "Authorization: token $TOKEN" -s $GITAPI_RESTURL_TREES)"
else
	HTTP_CODE="$(curl -sq -w "%{http_code}" -o $jsonFile -s $GITAPI_RESTURL_TREES)"
fi

rc=$?
if (( $rc != 0 )); then
	echo "??? Error retrieving repository contents from github. curl RC: $rc"
	exit 1
fi

if (( $HTTP_CODE != 200 )); then
	echo "??? Error retrieving repository contents from github. HTTP response: $HTTP_CODE"
	jq . $jsonFile
	exit 1
fi

files=( $(jq -r ".tree[].path" $jsonFile | egrep "*.sh") )

i=0
for f in ${files[@]}; do
	echo "$i: $f"
	(( i++ )) && true
done

while :; do
	read -p "Enter numbers of files to download separated by spaces > " nums
	if [[ ! $nums =~ ^[0-9]+([ ]+[0-9]+)?$ ]]; then
		echo "Invalid input '$nums'"
	else
		break
	fi
done

for i in $nums; do
	if [[ -z $nums ]]; then
		break
	fi
	if (( $i < 0 || $i > ${#files[@]} )); then
		echo "Skipping invalid number $i"
		continue
	fi
	echo "Downloading ${files[$i]} ..."
	curl -s -o ${files[$i]} $GIT_DOWNLOAD_PREFIX/${files[$i]}
	rc=$?
	if (( $rc != 0 )); then
		echo "??? Error downloading ${files[$i]}. curl RC: $rc"
		exit 1
	fi
	chmod +x ${files[$i]}

	if [[ "$fkt" == "install" ]]; then
		echo "Installing ${files[$i]} ..."
		sudo mv ${files[$i]} $INSTALL_DIR
	fi
done
