#!/bin/bash
#shellcheck disable=SC2004,SC2181
# (style): $/${} is unnecessary on arithmetic variables.
# (style): Check exit code directly with e.g. 'if ! mycmd;', not indirectly with $?.
#######################################################################################################################
#
#    This script uninstalls unused kernels on a Raspberry Pi running bookworm with option -u to speed up apt updates and
#    reinstalls the uninstalled kernels with option -r if the system should be run on a different Raspberry Pi HW
#
#	Either download this script
#	   curl -sO https://raw.githubusercontent.com/framps/raspberryTools/master/invokeTool.sh raspiHandleKernels.sh
#   and invoke
#      sudo ./raspiHandleKernels.sh <options>
#
#   or use following command to directly download and invoke syncUUIDs:
#     curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/invokeTool.sh | sudo bash -s -- raspiHandleKernels.sh.sh <options>
#	  	for example
#     curl -s https://raw.githubusercontent.com/framps/raspberryTools/master/invokeTool.sh | sudo bash -s -- raspiHandleKernels.sh
#

#
#######################################################################################################################
#
#    Copyright (c) 2023-2025 framp at linux-tips-and-tricks dot de
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

readonly VERSION="v0.3.1"
readonly GITREPO="https://github.com/framps/raspberryTools"

#shellcheck disable=SC2155
# (warning): Declare and assign separately to avoid masking return values.
readonly MYSELF="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
readonly MYNAME=${MYSELF%.*}
readonly VARLIBDIR="/var/lib/raspiHandleKernels"
readonly VARLIB_DELETED_KERNELS_FILENAME="$VARLIBDIR/$MYNAME.krnl"

#shellcheck disable=SC2155
# (warning): Declare and assign separately to avoid masking return values.
readonly DELETED_KERNELS_TEMP=$(mktemp)

declare -r PS4='|${LINENO}> \011${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

function err() {
    set +e
    echo "??? Unexpected error occured"
    local i=0
    local FRAMES=${#BASH_LINENO[@]}
    for ((i = FRAMES - 2; i >= 0; i--)); do
        echo '  File' \""${BASH_SOURCE[i + 1]}"\", line "${BASH_LINENO[i]}", in "${FUNCNAME[i + 1]}"
        sed -n "${BASH_LINENO[i]}{s/^/    /;p}" "${BASH_SOURCE[i + 1]}"
    done
}

function cleanup() {
    if [[ -f "$DELETED_KERNELS_TEMP" ]]; then
        rm "$DELETED_KERNELS_TEMP" &> /dev/null
    fi
}

trap 'err' ERR
trap 'cleanup' SIGINT SIGTERM SIGHUP EXIT

function show_help() {
    cat << EOH
$MYSELF $VERSION ($GITREPO)

* List unused and unnecessary kernels for the actual Raspberry hardware (-l)
* Uninstall unused kernels to speed up system updates and save which kernels are uninstalled for later reininstallation
* Reinstall the previously uninstalled kernels if the image should be used on different Raspberry hardware

Usage: $MYSELF -u | r | -? | -h | -v
	Default: List List kernels which can be uninstalled or reinstalled
-r: Reinstall uninstalled kernels
-u: Uninstall unused kernels
-h: Display this help
-v: Display version
EOH
}

function info() {
    echo "--- $*"
}

function error() {
    echo "??? $*"
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

    local availableKernels usedKernel unusedKernels keptKernel numUnusedKernels

    availableKernels="$(dpkg --list | awk '/^ii[[:space:]]+linux-image/ { print $2 }')"
    usedKernel="$(uname -a | awk '{ print "linux-image-" $3 }')"

    set +e
    unusedKernels="$(grep -v "$usedKernel" <<< "$availableKernels" | xargs -I {} echo "{}")"
    set -e
    if [[ -z "$unusedKernels" ]]; then
        info "$usedKernel installed only"
        if [[ ! -e "$VARLIB_DELETED_KERNELS_FILENAME" ]]; then
            info "$VARLIB_DELETED_KERNELS_FILENAME not found to reinstall unused kernels"
            exit 1
        fi
    fi

    set +e
    keptKernel="$(grep "$usedKernel" <<< "$availableKernels" | xargs -I {} echo "{}")"
    set -e
    if [[ -z "$keptKernel" ]]; then
        error "No kernel will be kept"
        exit 1
    fi

    info "Following kernel is used"
    echo "$keptKernel"

    numUnusedKernels="$(wc -l <<< "$unusedKernels")"

    if [[ -z "$unusedKernels" ]]; then
        info "No unused kernels found"
    else
        info "Following $numUnusedKernels kernels are not required and can be uninstalled to speed up system updates"
        info "Note the kernel names are saved in $VARLIB_DELETED_KERNELS_FILENAME and can be reinstalled if hardware changes"
        echo "$unusedKernels"

        if (($MODE_EXECUTE)); then

            local answer

            read -r -p "--- Are you sure to uninstall all $numUnusedKernels unused kernels ? (y/N) " answer
            if ! yesNo "$answer"; then
                exit 1
            fi

            read -r -p "--- Do you have a backup ? (y/N) " answer
            if ! yesNo "$answer"; then
                exit 1
            fi

            if [[ ! -d "$VARLIBDIR" ]]; then
                sudo mkdir "$VARLIBDIR"
            fi

            if [[ -e "$VARLIB_DELETED_KERNELS_FILENAME" ]]; then
                sudo cp "$VARLIB_DELETED_KERNELS_FILENAME" "$DELETED_KERNELS_TEMP"
                (($?)) && {
                    error "Copying $VARLIB_DELETED_KERNELS_FILENAME"
                    exit 42
                }
            fi

            info "Adding $numUnusedKernels unused kernel names in $VARLIB_DELETED_KERNELS_FILENAME"
            echo "$unusedKernels" >> "$DELETED_KERNELS_TEMP"
            #shellcheck disable=SC2320
            #(warning): This $? refers to echo/printf, not a previous command. Assign to variable to avoid it being overwritten.
            (($?)) && {
                error "Failure collecting kernels"
                exit 42
            }

            sort "$DELETED_KERNELS_TEMP" | uniq | sudo tee "$VARLIB_DELETED_KERNELS_FILENAME" > /dev/null
            (($?)) && {
                error "Failure sorting kernels"
                exit 42
            }

            rm "$DELETED_KERNELS_TEMP" &> /dev/null

            info "Removing $numUnusedKernels unused kernels"
            echo "$unusedKernels" | xargs sudo apt -y remove
            (($?)) && {
                error "Failure removing kernels"
                exit 42
            }
        else
            info "Use option -u to uninstall $numUnusedKernels unused kernels"
        fi
    fi
    return 0
}

function do_install() {

    local numUnusedKernels

    if [[ ! -e "$VARLIB_DELETED_KERNELS_FILENAME" ]]; then
        info "$VARLIB_DELETED_KERNELS_FILENAME not found to reinstall unused kernels"
        exit 1
    fi

    numUnusedKernels=$(wc -l "$VARLIB_DELETED_KERNELS_FILENAME" | cut -f 1 -d ' ')

    info "Following $numUnusedKernels unused kernels can be reinstalled"
    echo "$(< "$VARLIB_DELETED_KERNELS_FILENAME")"

    if ((!$MODE_EXECUTE)); then
        info "Use option -i to reinstall $numUnusedKernels unused kernels"
    else
        read -r -p "--- Are you sure to reinstall all $numUnusedKernels unused kernels ? (y/N) " answer
        if ! yesNo "$answer"; then
            exit 1
        fi

        local errorOccured=0
        info "Installing $numUnusedKernels unused kernels"
        while IFS= read -r line; do
            sudo apt -y install "$line"
            set +e
            ((errorOccured |= $?))
            set -e
            sudo apt-mark auto "$line"
            set +e
            ((errorOccured |= $?))
            set -e
        done < "$VARLIB_DELETED_KERNELS_FILENAME"
        if ((!errorOccured)); then
            info "Deleting $VARLIB_DELETED_KERNELS_FILENAME"
            sudo rm "$VARLIB_DELETED_KERNELS_FILENAME"
            (($?)) && {
                error "Failure removing $VARLIB_DELETED_KERNELS_FILENAME"
                exit 42
            }
            sudo rmdir "$VARLIBDIR"
            (($?)) && {
                error "Failure removing $VARLIB"
                exit 42
            }
        else
            error "Errors occured when reinstalling kernels"
        fi
    fi
    return 0
}

echo "$MYSELF $VERSION ($GITREPO)"

MODE_INSTALL=1 # 0 for uninstall
MODE_EXECUTE=0 # modify system

MODE_INSTALL=$(
    [[ ! -e "$VARLIB_DELETED_KERNELS_FILENAME" ]]
    echo $?
)

while getopts ":uhrv?" opt; do

    case "$opt" in
        u)
            MODE_EXECUTE=1
            MODE_INSTALL=0
            ;;
        r)
            MODE_EXECUTE=1
            MODE_INSTALL=1
            ;;
        h | \?)
            show_help
            exit 0
            ;;
        v)
            echo "$MYSELF $VERSION"
            exit 0
            ;;
        *)
            echo "Unknown option $opt"
            show_help
            exit 1
            ;;
    esac

done

shift $((OPTIND - 1))

if ! check4Pi; then
    error "No RaspberryPi detected"
    exit 1
fi

if (($MODE_INSTALL)); then
    do_install
else
    do_uninstall
fi
