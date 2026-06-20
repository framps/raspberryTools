# Proof of concept to retrieve BMW car data

## Scripts

### registerDevice.sh

This script will register the device the script is started so it can retrieve BMW car data.
A verification code will be created and has to be inserted on your BMW Portal to finally verify your cardata access. The link to the portal is displayed. 
Just copy and paste the URL into a browser to access the BMW Portal to enter the verification code. Finally an OAuthToken will be created and stored locally. This token is needed in following steps to access the BMW car data.

### getBasicData

This script will retrive some basic informations from BMW card data. Note there is a limit per day for these requests.

### subScribeStream

This script will subscribe to a MQTT port to receive any BMW data updates.

### refreshToken

The OAuthToken is valid for 1 hour and has to be refreshed earlier. Otherwise a new registration is required.
This script refreshes the OAuthToken.




