#!/bin/bash

#######################################################################################################################
#
#  Download any file available on raspberyyTools github repository into current directory
#
#  Example to download syncUUIDs tool
#     curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/invokeTool.sh | bash -s -- syncUUIDs.sh /dev/sda
#

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

MYSELF="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"					# use linked script name if the link is used
MYNAME=${MYSELF%.*}
GITHUBREPO="https://github.com/framps/raspberryTools"
GITHUBREPODOWNLOAD="https://raw.githubusercontent.com/framps/raspberryTools"

if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" || "$1" == "-?" || "$1" == "?" ]]; then
	echo "Purpose: Download any file from raspberryTools github repository."
	echo "Syntax:  $MYSELF fileName"
	echo "Example: $MYSELF syncUUIDs.sh"
	exit 1
fi

branch="master"
targetFilename="$1"
shift

downloadURL="$GITHUBREPODOWNLOAD/$branch/$targetFilename"

trap "rm -f $targetFilename" SIGINT SIGTERM EXIT

echo "--- Downloading $targetFilename from git branch $branch from $GITHUBREPO into current directory ..."
wget -q $downloadURL -O "$targetFilename"
rc=$?

if (( $rc != 0 )); then
	echo "??? Error occured downloading $downloadURL. RC: $rc"
	echo "??? Does $targetFilename exist in repository $GITHUBREPO?"
	exit 1
fi

echo "--- Download finished successfully"

trap - SIGINT SIGTERM EXIT

bash $targetFilename "$@"
