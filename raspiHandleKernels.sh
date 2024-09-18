#!/bin/bash

#######################################################################################################################
#
# 	 This script uninstalls unused kernels on a Raspberry Pi running bookworm with option -u and
#	 creates a file /boot/raspiHandleKernels.krnl with the uninstalled kernels in order to be able to reinstall them again
#
#	 Unless option -e is not used there is no modification on the system done
#
#######################################################################################################################
#
#    Copyright (c) 2023,2024 framp at linux-tips-and-tricks dot de
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

set -eou pipefail

readonly VERSION="v0.2.4"
readonly GITREPO="https://github.com/framps/raspberryTools"

readonly MYSELF="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
readonly MYNAME=${MYSELF%.*}
readonly DELETED_KERNELS_FILENAME="$MYNAME.krnl"

function show_help() {
	cat << EOH
$MYSELF $VERSION ($GITREPO)

Check for unnecessary kernels for the actual Raspberry hardware.
Optionally uninstall and save installed kernels for later reinstallation to speed up system updates
or
reinstall the previously uninstalled kernels if the image is used on a different Raspberry hardware

Usage: $MYSELF -i [-e] | -u [-e] | -h | -? | -v
-e: deactivate dry run mode and modify system
-i: reinstall kernels deleted with option -u
-u: uninstall any unused kernels
-h: display this help
-v: display version
EOH
}

function info() {
	echo "--- $@"
}

function error() {
	echo "??? $@"
}

function yesNo() {

	local answer=${1:0:1}
	answer=${1:-"n"}

	[[ "Yy" =~ $answer ]]
	return
}

function check4Pi() {
	dpkg --print-architecture | grep -q -E "arm(hf|64)"
}

function do_uninstall() {

	local availableKernels="$(dpkg --list | awk '/^ii[[:space:]]+linux-image/ { print $2 }')"
	local usedKernel="$(uname -a | awk '{ print "linux-image-" $3 }')"

	local unusedKernels="$(grep -v "$usedKernel" <<< "$availableKernels" | xargs -I {} echo "{}")"
	if [[ -z "$unusedKernels" ]]; then
		info "$usedKernel installed only"
		if [[ ! -e /boot/$DELETED_KERNELS_FILENAME ]]; then
			info "/boot/$DELETED_KERNELS_FILENAME not found to reinstall unused kernels"
			exit 1
		fi
	fi

	local keptKernel="$(grep "$usedKernel" <<< "$availableKernels" | xargs -I {} echo "{}")"
	if [[ -z "$keptKernel" ]]; then
		error "No kernel will be kept"
		exit 1
	fi

	info "Following kernel is used"
	echo "$keptKernel"

	local numUnusedKernels="$(wc -l <<< "$unusedKernels")"

	info "Following $numUnusedKernels kernels are not required and can be uninstalled to speed up system updates"
	info "Note the kernel names are saved in /boot/$DELETED_KERNELS_FILENAME and thus can be reinstalled if hardware changes"
	echo "$unusedKernels"

	if (( $MODE_EXECUTE )); then

		local answer

		read -p "--- Are you sure to uninstall all $numUnusedKernels unused kernels ? (y/N) " answer
		if ! yesNo "$answer"; then
			exit 1
		fi

		read -p "--- Do you have a backup ? (y/N) " answer
		if ! yesNo "$answer"; then
			exit 1
		fi

		set +e
		if [[ -e /boot/$DELETED_KERNELS_FILENAME ]]; then
			sudo rm /boot/$DELETED_KERNELS_FILENAME
			(( $? )) && { error "Failure deleting /boot/$DELETED_KERNELS_FILENAME"; exit 42; }
		fi

		info "Saving $numUnusedKernels unused kernel names in /boot/$DELETED_KERNELS_FILENAME"
		echo "$unusedKernels" >> $DELETED_KERNELS_FILENAME; sudo mv $DELETED_KERNELS_FILENAME /boot
		(( $? )) && { error "Failure collecting kernels"; exit 42; }

		info "Removing $numUnusedKernels unused kernels"
		echo "$unusedKernels" | xargs sudo apt -y remove
		(( $? )) && { error "Failure removing kernels"; exit 42; }
		set -e
	else
		info "Use option -e to uninstall $numUnusedKernels unused kernels"
	fi
}

function do_install() {

	if [[ ! -e /boot/$DELETED_KERNELS_FILENAME ]]; then
		info "/boot/$DELETED_KERNELS_FILENAME not found to reinstall unused kernels"
		exit 1
	fi

	local numUnusedKernels=$(wc -l /boot/$DELETED_KERNELS_FILENAME | cut -f 1 -d ' ')

	info "Following $numUnusedKernels unused kernels can be reinstalled"
	echo "$(</boot/$DELETED_KERNELS_FILENAME)"

	if (( ! $MODE_EXECUTE )); then
		info "Use option -e to reinstall $numUnusedKernels unused kernels"
	else
		read -p "--- Are you sure to reinstall all $numUnusedKernels unused kernels ? (y/N) " answer
		if ! yesNo "$answer"; then
			exit 1
		fi

		local errorOccured=0
		info "Installing $numUnusedKernels unused kernels"
		while IFS= read -r line; do
			sudo apt -y install $line
			set +e
			(( errorOccured |= $? ))
			set -e
		done < /boot/$DELETED_KERNELS_FILENAME
		if (( ! errorOccured )); then
			sudo rm /boot/$DELETED_KERNELS_FILENAME
		else
			error "Errors occured when reinstalling kernels"
		fi
	fi
}

echo "$MYSELF $VERSION ($GITREPO)"

MODE_INSTALL=1 # 0 for uninstall
MODE_EXECUTE=0 # modify system

MODE_INSTALL=$( [[ ! -e /boot/$DELETED_KERNELS_FILENAME ]]; echo $? )

while getopts ":ehv?" opt; do

	case "$opt" in
		e) MODE_EXECUTE=1
			;;
		h|\?)
			show_help
			exit 0
			;;
		v) echo "$MYSELF $VERSION"
			exit 0
			;;
		*) echo "Unknown option $opt"
			show_help
			exit 1
			;;
	esac

done

if ! check4Pi; then
	error "No RaspberryPi detected"
	exit 1
fi

if (( $MODE_INSTALL )); then
	do_install
else 
	do_uninstall
fi
