#!/bin/bash

#######################################################################################################################
#
# 	 This script deletes unused kernels on a Raspberry Pi running bookworm with option -u and
#	 creates a file /boot/raspiHandleKernels.krnl in order to be able to reinstall the deleted kernels with option -i
#
#	 Use option -e to execute the updates on the system. Otherwise it's just a dry run.
#
#######################################################################################################################
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

set -eou pipefail

readonly VERSION="v0.1"

readonly MYSELF="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
readonly MYNAME=${MYSELF%.*}
readonly DELETED_KERNELS_FILENAME="$MYNAME.krnl"
readonly INITRD_GREP_REGEX="^initrd\.img.+-rpi+"
readonly INITRD_DELETE_SED="s/^initrd\.img/linux-image/"

readonly OS_RELEASE="/etc/os-release"

function show_help() {
	echo "$MYSELF -i [-e] | -u [-e] | -h | -? | -v"
	echo "-e: deactivate dry run mode and modify system"
	echo "-i: reinstall kernels deleted with option -u"
	echo "-u: uninstall any unused kernels"
	echo "-h: display this help"
	echo "-v: display version"
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

function check4Bookworm() {
	if [[ -e $OS_RELEASE ]]; then
		grep -qi '^VERSION_CODENAME=bookworm' $OS_RELEASE
		return 
	fi
	return 1
}

function do_uninstall() {

	local unusedKernels="$(ls -1 /boot | grep -v -E $(uname -r) | grep -E "$INITRD_GREP_REGEX" | sed "$INITRD_DELETE_SED" | xargs -I {} echo "{}")"
	if [[ -z "$unusedKernels" ]]; then
		error "No unused kernels detected"
		exit 1
	fi
	local keptKernels="$(ls -1 /boot | grep -E $(uname -r) | grep -E "$INITRD_GREP_REGEX" | sed "$INITRD_DELETE_SED" | xargs -I {} echo "{}")"
	if [[ -z "$keptKernels" ]]; then
		error "No kernels will be kept"
		exit 1
	fi

	info "Following kernel will be kept"
	echo "$keptKernels"

	local numUnusedKernels="$(wc -l <<< "$unusedKernels")"

	info "Following $numUnusedKernels unused kernels will be deleted"
	echo "$unusedKernels"

	if (( $MODE_EXECUTE )); then

		local answer

		read -p "Are you sure to delete all $numUnusedKernels unused kernels ? (y/N) " answer
		if ! yesNo "$answer"; then
			exit 1
		fi

		read -p "Do you have a backup ? (y/N) " answer
		if ! yesNo "$answer"; then
			exit 1
		fi

		set +e
		if [[ -e /boot/$DELETED_KERNELS_FILENAME ]]; then
			sudo rm /boot/$DELETED_KERNELS_FILENAME
			(( $? )) && { error "Failure deleting /boot/$DELETED_KERNELS_FILENAME"; exit 42; }
		fi

		info "Saving $numUnusedKernels unused kernel names in /boot/$DELETED_KERNELS_FILENAME"
		ls -1 /boot | grep -v -E $(uname -r) | grep -E "$INITRD_GREP_REGEX" | sed "$INITRD_DELETE_SED" | xargs -I {} echo -e "{}" >> $DELETED_KERNELS_FILENAME; sudo mv $DELETED_KERNELS_FILENAME /boot
		(( $? )) && { error "Failure collecting kernels"; exit 42; }

		info "Removing $numUnusedKernels unused kernels"
		ls -1 /boot | grep -v -E $(uname -r) | grep -E "$INITRD_GREP_REGEX" | sed "$INITRD_DELETE_SED" | xargs sudo apt -y remove
		(( $? )) && { error "Failure removing kernels"; exit 42; }
		set -e
	fi
}

function do_install() {

	if [[ ! -e /boot/$DELETED_KERNELS_FILENAME ]]; then
		error "Missing /boot/$DELETED_KERNELS_FILENAME to reinstall unused kernels"
		exit 42
	fi
	
	local numUnusedKernels=$(wc -l /boot/$DELETED_KERNELS_FILENAME | cut -f 1 -d ' ')
	
	if (( ! $MODE_EXECUTE )); then
		info "Following $numUnusedKernels unused kernels will be installed"
		while IFS= read -r line; do
			echo "$line"
		done < /boot/$DELETED_KERNELS_FILENAME
	else
		info "Installing $numUnusedKernels unused kernels"
		echo "$(</boot/$DELETED_KERNELS_FILENAME)"
		while IFS= read -r line; do
			sudo apt install $line
		done < /boot/$DELETED_KERNELS_FILENAME
	fi
}

if ! check4Pi; then
	error "No RaspberryPi detected"
	exit 1
fi

if ! check4Bookworm; then
	error "No Bookworm detected"
	exit 1
fi

MODE_INSTALL=0
MODE_UNINSTALL=0
MODE_EXECUTE=0

while getopts ":ehiuv?" opt; do

    case "$opt" in
		e) MODE_EXECUTE=1
			;;
		h|\?)
			show_help
			exit 0
			;;
		i) MODE_INSTALL=1
			;;
		u) MODE_UNINSTALL=1
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

if (( $MODE_INSTALL )); then
	do_install
elif (( $MODE_UNINSTALL )); then
	do_uninstall
else
	show_help
fi
