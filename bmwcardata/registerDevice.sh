#!/bin/bash
#
# Proof of concept code to retrieve BMW car data
#
# Step 1: Register a device to access BMW car data and create an oauth token
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

if [[ ! -f $CONFIG_FILE ]]; then
	echo "CLIENT_ID=" > $CONFIG_FILE
	echo "VIN=" >> $CONFIG_FILE
	echo "$CONFIG_FILE created. Define CLIENT_ID and VIN and invoke script once more"
	exit 1
else
	source $CONFIG_FILE
fi

CODE_VERIFIER="$(openssl rand -base64 64 | tr -d '\n' | tr -d '=+/' | cut -c1-64)"

CODE_CHALLENGE=$(printf '%s' "$CODE_VERIFIER" \
  | openssl dgst -binary -sha256 \
  | openssl base64 \
  | tr '+/' '-_' \
  | tr -d '=')

result="$(curl -s -X 'POST' \
  'https://customer.bmwgroup.com/gcdm/oauth/device/code' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "client_id=$CLIENT_ID" \
  -d 'response_type=device_code' \
  -d 'scope=authenticate_user%20openid%20cardata%3Aapi%3Aread%20cardata%3Astreaming%3Aread' \
  -d "code_challenge=$CODE_CHALLENGE" \
  -d 'code_challenge_method=S256')"

DEVICE_CODE="$(jq -r .device_code <<< "$result")"
USER_CODE="$(jq -r .user_code <<< "$result")"
VERIFICATION_URI="$(jq -r .verification_uri <<< "$result")"

echo "Now verify this client with \"$USER_CODE\" on \"$VERIFICATION_URI\" ... and press ENTER afterwards to create an oauth token..."
read

response="$(curl -s -X 'POST' \
  'https://customer.bmwgroup.com/gcdm/oauth/token' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "client_id=$CLIENT_ID" \
  -d "device_code=$DEVICE_CODE" \
  -d 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Adevice_code' \
  -d "code_verifier=$CODE_VERIFIER")"

echo "$response" | jq '.' > oauthToken.json

ACCESS_TOKEN="$(jq -r .access_token <<< "$response")"		# required for API calls, valid for 1 hour, 50 API requests per day allowed
REFRESH_TOKEN="$(jq -r .refresh_token <<< "$response")"		# required to refresh oauth token, valid for 2 weeks
GCID="$(jq -r .gcid <<< "$response")"						# userid in MQTT requests
ID_TOKEN="$(jq -r .id_token <<< "$response")"				# password in MQTT requests, valid for 1 hour

echo "ACCESS_TOKEN=\"$ACCESS_TOKEN\"" > $TOKEN_FILE
echo "REFRESH_TOKEN=\"$REFRESH_TOKEN\"" >> $TOKEN_FILE
echo "GCID=\"$GCID\"" >> $TOKEN_FILE
echo "ID_TOKEN=\"$ID_TOKEN\"" >> $TOKEN_FILE

echo "$TOKEN_FILE created"

