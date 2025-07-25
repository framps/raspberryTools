#!/bin/bash
#######################################################################################################################
#
#  Convenient script to download selected raspberryTools to evaluate and optionally to install them
#
#	1) A list of all scripts in raspberryTools is presented and the scripts to download can be selected
#	2) Selected files are downloaded into ./raspberryTools
#	3) Scripts can be tested (Don't forget to prefix commands with ./ )
#	4) Then either delete ./raspberyTools directory or use option install to downloaded and install selected tools into /usr/local/bin
#
#   There is no need to download this script. Just use following oneliner
#
#      curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/downloadRepoFiles.sh -o downloadRepoFiles.sh; bash ./downloadRepoFiles.sh -t
#         to download any script into a testdirectory without installing it in /usr/local/bin
#   or
#      curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/downloadRepoFiles.sh -o downloadRepoFiles.sh; bash ./downloadRepoFiles.sh -i
#         to download and install any script into /usr/local/bin
#
#######################################################################################################################
#
#    Copyright (c) 2024-2025 framp at linux-tips-and-tricks dot de
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

readonly VERSION="v0.1.5"
readonly GITREPO="https://github.com/framps/raspberryTools"

readonly GITAPI_RESTURL_TREES="https://api.github.com/repos/framps/raspberryTools/git/trees/master?recursive=1"
readonly GIT_DOWNLOAD_PREFIX="https://raw.githubusercontent.com/framps/raspberryTools/master"
readonly INSTALL_DIR="/usr/local/bin"
#shellcheck disable=SC2155
# (warning): Declare and assign separately to avoid masking return values
readonly TEST_DIR="$(pwd)/raspberryTools"
readonly TEST_OPTION="-t"
readonly INSTALL_OPTION="-i"

MYSELF="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"					# use linked script name if the link is used
MYNAME=${MYSELF%.*}

echo "$MYSELF $VERSION ($GITREPO)"

fkt=""
if (( $# != 0 )); then
	fkt="$1"
fi

if (( $# == 0 )) || [[ "$fkt" == "-h" || "$fkt" == "--help" || "$fkt" == "-?" || "$fkt" == "?" ]]; then
	echo "Purpose: Download and test selected files from raspberryTools github repository."
	echo "Syntax:  $MYSELF $TEST_OPTION      - Select files to download into $TEST_DIR"
	echo "         $MYSELF $INSTALL_OPTION      - Select files to download and install into /usr/local/bin"
	exit 0
fi

pwd=$PWD

jsonFile=$(mktemp)
trap '{ rm -f $jsonFile; }' SIGINT SIGTERM EXIT

if [[ ! $fkt =~ $TEST_OPTION|$INSTALL_OPTION ]]; then
	echo "Unknown option \"$fkt\""
	exit 1
fi

if ! which jq &>/dev/null; then
	echo "... Installing jq required by $MYNAME."
	sudo apt install jq
	if ! which jq &>/dev/null; then
		echo "??? jq required by $MYNAME. Automatic jq installation failed. Please install jq manually."
		exit 1
	fi
fi

[[ ! -d "$TEST_DIR" ]] && mkdir "$TEST_DIR"

cd "$TEST_DIR"

echo "--- Available raspberyTools ---"
TOKEN=""															# Personal token to get better rate limits
if [[ -n $TOKEN ]]; then
	HTTP_CODE="$(curl -sq -w "%{http_code}" -o "$jsonFile" -H "Authorization: token $TOKEN" -s "$GITAPI_RESTURL_TREES")"
else
	HTTP_CODE="$(curl -sq -w "%{http_code}" -o "$jsonFile" -s "$GITAPI_RESTURL_TREES")"
fi

rc=$?
(( rc != 0 )) &&  { echo "??? Error retrieving repository contents from github. curl RC: $rc"; exit 1; }

(( HTTP_CODE != 200 )) && { echo "??? Error retrieving repository contents from github. HTTP response: $HTTP_CODE"; jq . "$jsonFile"; }

#shellcheck disable=SC2207
# (warning): Prefer mapfile or read -a to split command output (or quote to avoid splitting).
files=( $(jq -r ".tree[].path" "$jsonFile" | grep -E '\.sh' | grep -v "$MYSELF") )

i=0
for f in "${files[@]}"; do
	echo "$i: $f"
	(( i++ )) && true
done

fktDesc="download into $TEST_DIR"
if [[ "$fkt" == "$INSTALL_OPTION" ]]; then
	fktDesc="install into $INSTALL_DIR"
fi

while :; do
	nums=""
	read -r -p "Enter numbers of files to $fktDesc separated by spaces > " nums
	if [[ -z $nums ]]; then
		exit
	fi
	if [[ ! $nums =~ ^[0-9]+([ ]+[0-9]+)*$ ]]; then
		echo "Invalid input '$nums'"
	else
		break
	fi
done

if [[ -z $nums ]]; then
	exit 0
fi

for i in $nums; do
	if (( i < 0 || i > ${#files[@]} )); then
		echo "Skipping invalid number $i"
		continue
	fi
	echo "Downloading ${files[$i]} ..."
	if ! curl -s -o "${files[$i]}" "$GIT_DOWNLOAD_PREFIX/${files[$i]}"; then
		{ echo "??? $LINENO: Error downloading ${files[$i]}. curl RC: $rc"; exit 1; }
	fi
	if ! chmod +x "${files[$i]}"; then
		{ echo "??? $LINENO: Error chmod"; exit 1; }
	fi

	if [[ "$fkt" == "$INSTALL_OPTION" ]]; then
		echo "Installing ${files[$i]} into $INSTALL_DIR"
		if ! chown root:root "${files[$i]}"; then
			{ echo "??? $LINENO: Error chown"; exit 1; }
		fi
		if ! chmod 755 "${files[$i]}"; then
			{ echo "??? $LINENO: Error chmod"; exit 1; }
		fi
		if ! sudo mv "${files[$i]}" "$INSTALL_DIR"; then
			{ echo "??? $LINENO: Error mv"; exit 1; }
		fi
	fi
done

if [[ "$fkt" == "$INSTALL_OPTION" ]]; then
	if [[ -d "$TEST_DIR" ]]; then
		cd "$TEST_DIR"
		if [[ -n $(ls "$TEST_DIR") ]]; then
			rm "$TEST_DIR/*"
		fi
		cd "$pwd"
		rmdir "$TEST_DIR"
	fi
else
	cd "$TEST_DIR"
	echo "Now test raspberryTools."
	echo "Don't forget the leading ./ for any command ;-)"
fi
