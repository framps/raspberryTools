#!/bin/bash
#
# Proof of concept code to retrieve BMW car data
#
# Step 2: Retrieve car data from API
# Note: Only 50 API calls allowed per day ! Other wise you get a 403 (Rate limit exceeded)
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

response="$(curl -s -X 'GET' \
   "https://api-cardata.bmwgroup.com/customers/vehicles/$VIN/basicData" \
   -H 'accept: application/json' \
   -H 'x-version: v1' \
   -H "Authorization: Bearer $ACCESS_TOKEN")"

echo "$response" | jq
