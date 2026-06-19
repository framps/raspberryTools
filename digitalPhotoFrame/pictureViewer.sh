#!/bin/bash
#######################################################################################################################
#
# 	Simple digital photo frame which displays photos and videos with a Raspberry Pi Zwero 2 W on any monitor
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

VERSION=0.1
GITREPO="https://github.com/framps/raspberryTools"

MYSELF="$(basename "$0")"
MYNAME=${MYSELF%.*}
PHOTOS="/photos"

echo "$MYSELF $VERSION ($GITREPO)"

while true; do
  mpv --fs \
    --image-display-duration=15 \
    --vo=drm \
    --hwdec=no \
    --cache=no \
    --really-quiet \
    --shuffle \
   "$PHOTOS" 

  sleep 2
done
