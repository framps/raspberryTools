#!/bin/bash
#
# Proof of concept code to retrieve BMW car data
#
# Step 3: Retrieve car data with a stream
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

source ./common.sh

requireBothConfigs
require mosquitto_sub

echo "--- Subscribing for updates on $VIN"
mosquitto_sub -h customer.streaming-cardata.bmwgroup.com -p 9000 -u $GCID -P $ID_TOKEN -t "$GCID/$VIN" --capath /etc/ssl/certs -k 15 
