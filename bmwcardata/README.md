# Proof of concept to retrieve BMW car data

## Scripts

### registerDevice.sh

This script will register the device the script is started so it can retrieve BMW car data.
A code will be created and has to be inserted on your BMW Portal. The link to the portal is given.
Finally an OAuthToken will be created and stored locally. This token is reuqired to retrieve
BMW car data.

### getBasicData

This script will retrive some basic informations from BMW card data.

### subScribeStream

This script will subscribe to a MQTT port to receive any BMW data updates.

### refreshToken

The OAuthToken is valid for 1 hour and has to be refreshed earlier. Otherwise a new registration is required.
This script refreshes the OAuthToken.




