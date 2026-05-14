#!/bin/bash
#
# Proof of concept code to retrieve BMW car data
#
# Step 4: Refresh oauth token, token is valid only for 1 hour
#
# See https://bmw-cardata.bmwgroup.com/customer/public/api-documentation 
# See https://bmw-cardata.bmwgroup.com/customer/public/api-specification for API Doc with Swagger

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

response="$(curl -s -X 'POST' \
  'https://customer.bmwgroup.com/gcdm/oauth/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d grant_type=refresh_token \
  -d refresh_token=$REFRESH_TOKEN \
  -d client_id=$CLIENT_ID)"

echo "$response" | jq '.' > oauthToken.json

BEARER_TOKEN="$(jq -r .access_token <<< "$response")"
REFRESH_TOKEN="$(jq -r .refresh_token <<< "$response")"
GCID="$(jq -r .gcid <<< "$response")"						# userid in MQTT requests
ID_TOKEN="$(jq -r .id_token <<< "$response")"				# password in MQTT requests, valid for 1 hour

echo "ACCESS_TOKEN=\"$ACCESS_TOKEN\"" > $TOKEN_FILE
echo "REFRESH_TOKEN=\"$REFRESH_TOKEN\"" >> $TOKEN_FILE
echo "GCID=\"$GCID\"" >> $TOKEN_FILE
echo "ID_TOKEN=\"$ID_TOKEN\"" >> $TOKEN_FILE

echo "--- $TOKEN_FILE updated"
