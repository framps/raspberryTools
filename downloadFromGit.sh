#!/bin/bash
#######################################################################################################################
#
#  Download any file available on any github repository branch or a git commit level into current directory
#
#  Example to download latest raspiBackup.sh from master branch:
#  curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/scripts/downloadFromGit.sh | bash -s --  framps/raspiBackup master
#
#  Example to download latest raspiBackupWrapper.sh from master branch:
#  curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/scripts/downloadFromGit.sh | bash -s -- framps/raspiBackup helper/raspiBackupWrapper.sh
#
#  Example to download latest raspiBackupInstallUI.sh from beta branch:
#  curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/scripts/downloadFromGit.sh | bash -s -- framps/raspiBackup installation/raspiBackupInstallUI.sh beta
#
#  Example to download raspiBackup.sh commited in 609632b1e17e924b9b3c94a6e4d34fe60f4412ed:
#  curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/scripts/downloadFromGit.sh | bash -s -- framps/raspiBackup raspiBackup.sh 609632b1e17e924b9b3c94a6e4d34fe60f4412ed 
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
#######################################################################################################################

MYSELF="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"					# use linked script name if the link is used

readonly VERSION="0.1"
readonly GITREPO="https://github.com/framps/raspberryTools"

if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" || "$1" == "-?" || "$1" == "?" ]]; then
	echo "$MYSELF $VERSION ($GITREPO)"
	echo "Purpose: Download any file from any github repository branch or commit."
	echo "Syntax:  $MYSELF repository  fileName [branchName|commit]"
	echo "Example: $MYSELF framps/raspiBackup helper/raspiBackupWrapper.sh master"
	echo "If the file resides in a subdirectory prefix fileName with the directories."
	echo "Default branch is master"
	exit 1
fi

repo="$1"
downloadFile="$2"
branch="${3:-master}"
shift

echo "$MYSELF $VERSION ($GITREPO)"

downloadURL="https://raw.githubusercontent.com/$repo/$branch/$downloadFile"
targetFilename="$(basename "$downloadFile")"

rm -f "$targetFilename"

trap 'rm -f $targetFilename' SIGINT SIGTERM EXIT

echo "--- Starting download of $downloadFile from git repo $repo and branch $branch into current directory ..."
wget -q "$downloadURL" -O "$targetFilename"
rc=$?

if (( rc != 0 )); then
	echo "??? File $downloadFile/$branch not found in $repo"
	exit 1
fi

echo "--- Download finished successfully"

trap - SIGINT SIGTERM EXIT

if [[ "$targetFilename" == *\.sh ]]; then
	chmod +x "$targetFilename"
	echo "--- Start $targetFilename with \`./$targetFilename\` now. NOTE THE LEADING PERIOD !"
fi

