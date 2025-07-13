#!/bin/bash
#
# Script checks for common network configuration errors on
# Raspberry Pi and collects various network configuration
# information which should speed up the network error detection.
# No modifications are done on the system. The results are displayed
# and are available in parallel in file raspiNetInfo.log.
# SSID, non local IPs, MACs and other sensitive data is masqueraded
# as good as possible.
#
# Invocation: curl -s https://raw.githubusercontent.com/framps/raspberryTools/refs/heads/master/raspiNetInfo.sh |  bash -s -- -e
#          or curl -s https://raw.githubusercontent.com/framps/raspberryTools/refs/heads/master/raspiNetInfo.sh |  bash -s -- -s
#
# Script testet auf häufige Konfigurationsfehler bei der Pi
# und sammelt verschiedene Netzwerkkonfigurationsinformationen
# die die Netzwerkfehlersuche beschleunigen
# Es werden nur Informationen gesammelt und keine Änderungen
# am System vorgenommen. Die Untersuchungsergebnisse werden
# angezeigt und finden sich parallel in der Datei raspiNetInfo.log.
# Die SSID, die nicht lokalen IPs sowie die MACs und weitere sensible
# Daten werden soweit wie moeglich in den Ausgaben maskiert.
#
# Aufruf: curl -s https://raw.githubusercontent.com/framps/raspberryTools/refs/heads/master/raspiNetInfo.sh |  bash -s -- -e
#    oder curl -s https://raw.githubusercontent.com/framps/raspberryTools/refs/heads/master/raspiNetInfo.sh |  bash -s -- -s
#
#    Copyright (C) 2013-2025 framp at linux-tips-and-tricks dot de
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

MYSELF="${0##*/}"
VERSION="V0.2.14"

GIT_DATE="$Date$"
GIT_DATE_ONLY=${GIT_DATE/: /}
GIT_DATE_ONLY=$(echo $GIT_DATE | cut -f 2 -d ' ')
GIT_TIME_ONLY=$(echo $GIT_DATE | cut -f 3 -d ' ') 
GIT_COMMIT="$Sha1$"
GIT_COMMIT_ONLY=$(echo $GIT_COMMIT | cut -f 2 -d ' ' | sed 's/\$//')
GIT_CODEVERSION="$MYSELF $VERSION, $GIT_DATE_ONLY/$GIT_TIME_ONLY - $GIT_COMMIT_ONLY"

LANGUAGE_NOT_SUPPORTED_WRITTEN=0
LICENSE="This program comes with ABSOLUTELY NO WARRANTY; This is free software, and you are welcome to redistribute it under certain conditions"
   
# Alle messages are logged in file also 
                     
LOG_FILE=${MYSELF/.sh/}.log
rm -f $LOG_FILE 1>/dev/null 2>&1

exec 1> >(tee -a $LOG_FILE >&1)
exec 2> >(tee -a $LOG_FILE >&2)

#################################################################################
#
# --- Messages in English and German
#
# (volunteers to translate the messages into other languages are welcome)
#
#################################################################################

# supported languages

MSG_EN=1      # english	(default)
MSG_DE=1      # german

MSG_UNDEFINED=0
MSG_EN[$MSG_UNDEFINED]="RNI0001E: Undefined message. Pls inform the author %1"
MSG_DE[$MSG_UNDEFINED]="RNI0001E: Unbekannte Meldung. Bitte den Author %1 informieren"
MSG_MISSING_COMMANDS=1
MSG_EN[$MSG_MISSING_COMMANDS]="RNI002W: Following commands are missing and reduce the value of the analysis result: %1 %2 %3 %4 %5 %6 %7 %8 %9 %10"
MSG_DE[$MSG_MISSING_COMMANDS]="RNI002W: Folgende Befehle sind nicht verfügbar und reduzieren die Effektivität des Scripts: %1 %2 %3 %4 %5 %6 %7 %8 %9 %10"
MSG_DNS_NOT_REACHABLE=2
MSG_EN[$MSG_DNS_NOT_REACHABLE]="RNI002E: Nameserver %1 not accessible"
MSG_DE[$MSG_DNS_NOT_REACHABLE]="RNI002E: Der Nameserver %1 ist nicht erreichbar"
MSG_AP_WITH_SSID_NOT_FOUND=3
MSG_EN[$MSG_AP_WITH_SSID_NOT_FOUND]="RNI003E: No accespoint with passed SSID found"
MSG_DE[$MSG_AP_WITH_SSID_NOT_FOUND]="RNI003E: Keinen Accesspoint mit eingegebener SSID gefunden"
MSG_SSID_INVALID=4
MSG_EN[$MSG_SSID_INVALID]="RNI004E: Passed SSID contains invalid characters"
MSG_DE[$MSG_SSID_INVALID]="RNI004E: Eingegebene SSID beinhaltet ungültige Zeichen"
MSG_UNKNONW_OPTION=5
MSG_EN[$MSG_UNKNONW_OPTION]="RNI005E: Unknown option %1"
MSG_DE[$MSG_UNKNONW_OPTION]="RNI005E: Unbekannte Option %1"
MSG_OPTION_REQUIRES_ARGS=6
MSG_EN[$MSG_OPTION_REQUIRES_ARGS]="RNI006E: Option %1 requires an argument"
MSG_DE[$MSG_OPTION_REQUIRES_ARGS]="RNI006E: Option %1 erwarte ein Argument"
MSG_MISSING_MANDATORY_PARM=7
MSG_EN[$MSG_MISSING_MANDATORY_PARM]="RNI007E: Either -e or -s SSID has to be used"
MSG_DE[$MSG_MISSING_MANDATORY_PARM]="RNI007E: Entweder muss -e oder -s SSID angegeben werden"
MSG_MISSING_DNS=8
MSG_EN[$MSG_MISSING_DNS]="RNI008E: No nameserver defined"
MSG_DE[$MSG_MISSING_DNS]="RNI008E: Kein DNS Nameserver definiert"
MSG_INVALID_DNS=9
MSG_EN[$MSG_INVALID_DNS]="RNI009E: Configured nameserver $ip is no nameserver"
MSG_DE[$MSG_INVALID_DNS]="RNI009E: Der konfigurierte Nameserver $ip ist kein Nameserver"
MSG_STARTING_DATA_COLLECTION=10
MSG_EN[$MSG_STARTING_DATA_COLLECTION]="RNI010I: Starting collection of data and network analysis. This may take some time ..."
MSG_DE[$MSG_STARTING_DATA_COLLECTION]="RNI010I: Starte Datensammlung und Netzwerkuntersuchung. Das kann u.U. ein paar Minuten dauern ..."
MSG_NO_STD_GATEWAY_DEFINED=11
MSG_EN[$MSG_NO_STD_GATEWAY_DEFINED]="RNI011E: There is no standard gateway defined"
MSG_DE[$MSG_NO_STD_GATEWAY_DEFINED]="RNI011E: Es ist kein Standardgateway definiert"
MSG_PING_OK=12
MSG_EN[$MSG_PING_OK]="RNI012I: Ping of %1 successful"
MSG_DE[$MSG_PING_OK]="RNI012I: Ping von %1 erfolgreich"
MSG_PING_FAILED=13
MSG_EN[$MSG_PING_FAILED]="RNI013E: Ping of %1 failed"
MSG_DE[$MSG_PING_FAILED]="RNI013E: Ping von %1 nicht erfolgreich"
#MSG_LANGUAGE_NOT_SUPPORTED=14 
MSG_DNS_PING_FAILED=15
MSG_EN[$MSG_DNS_PING_FAILED]="RNI015E: Ping of nameserver %1 failed"
MSG_DE[$MSG_DNS_PING_FAILED]="RNI015E: Ping von Nameserver %1 nicht erfolgreich"
MSG_CHECK_OUTPUT=16
MSG_EN[$MSG_CHECK_OUTPUT]="RNI016I: Check logfile %1 for sensitive data before publishing"
MSG_DE[$MSG_CHECK_OUTPUT]="RNI016I: Vor dem Publizieren von der Logdatei %1 immer kontrollieren, dass keine sensitiven Daten enthalten sind"
MSG_SKIPPING_TEST=17
MSG_EN[$MSG_SKIPPING_TEST]="RNI017W: One test is skipped because of missing package %1"
MSG_DE[$MSG_SKIPPING_TEST]="RNI017W: Ein Test wird wegen fehlendem Paket %1 nicht vorgenommen"
MSG_ENABLE_RUN_WITH_MISSING_PACKAGES=18
MSG_EN[$MSG_ENABLE_RUN_WITH_MISSING_PACKAGES]="RNI018I: Some required packages are not installed. Option -m will ignore them and run the program with reduced analysis capabilities"
MSG_DE[$MSG_ENABLE_RUN_WITH_MISSING_PACKAGES]="RNI018I: Es fehlen notwendige Pakete. Mit der Option -m läuft das Programm mit reduzierter Fähigkeit trotzdem durch"
MSG_SKIPPING_OUTPUT=19
MSG_EN[$MSG_SKIPPING_OUTPUT]="RNI019W: Some network data cannot be retrieved because of missing package %1"	
MSG_DE[$MSG_SKIPPING_OUTPUT]="RNI019W: Eine Ausgabe kann wegen fehlendem Paket %1 nicht erstellt werden"
MSG_APT_HINT=20
MSG_EN[$MSG_APT_HINT]="RNI020I: 'sudo apt-get update; sudo apt-get install %1' will install the missing network tools if there exist a working wired network connection"
MSG_DE[$MSG_APT_HINT]="RNI020I: 'sudo apt-get update; sudo apt-get install %1' wird die noch notwendigen Netzwerktools installieren sofern eine funktionierende Netzwerkverbindung per Kabel existiert"
MSG_USAGE=21
MSG_EN[$MSG_USAGE]="RNI021I: Aufruf: $MYSELF [-e | -s SSID | -h | -m | -g | -l LANGUAGE]\nParameter:\n-e : Test wired connection only\n-h : help\n-m : Ignore missing networking packages\n-s : Test wired and wireless connection\n-g : Messages in English only\n-l : Write messages in selected language if supported (de|en)"
MSG_DE[$MSG_USAGE]="RNI020I: Invocation: $MYSELF [-e | -s SSID | -h | -m | -g | -l LANGUAGE]\nParameter:\n-e : Nur Kabelverbindung testen\n-h : help\n-m : Fehlende Netzwerkpakete ignorieren\n-s : WLAN und Kabelverbindung testen\n-g : Meldungen in Englisch\n-l : Meldungen in der gewählten Sprache schreiben sofern verfügbar (de|en)"
MSG_MISSING_RESOLV_CONF=22
MSG_EN[$MSG_MISSING_RESOLV_CONF]="RNI022E: /etc/resolv.conf missing"
MSG_DE[$MSG_MISSING_RESOLV_CONF]="RNI022E: Es fehlt eine /etc/resolv.conf"
MSG_NO_IP_ASSIGNED=23
MSG_EN[$MSG_NO_IP_ASSIGNED]="RNI023W: No IP assigned to %1"
MSG_DE[$MSG_NO_IP_ASSIGNED]="RNI023W: Keine IP bei %1 gefunden"
	
declare -A MSG_HEADER=( ['I']="---" ['W']="!!!" ['E']="???" )
	
# Create message and substitute parameters

function getMessageText() {         # languageflag messagenumber parm1 parm2 ...
   local msg
   local p
   local i
   local s

   if (( $NO_XLATION )); then
      msg=${MSG_EN[$2]};             # just use english
   else

	  if [[ $1 != "L" ]]; then
		LANG_SUFF=$(echo $1 | tr '[:lower:]' '[:upper:]')
	  else
		LANG_EXT=$(echo $LANG | tr '[:lower:]' '[:upper:]')
		LANG_SUFF=${LANG_EXT:0:2}
	  fi

      msgVar="MSG_${LANG_SUFF}"

      if [[ -n ${!msgVar} ]]; then
         msgVar="$msgVar[$2]"
         msg=${!msgVar}
         if [[ -z $msg ]]; then		                  # no translation found
			msg=${MSG_EN[$2]};      	    	          # fallback into english
		 fi
      else
		  msg=${MSG_EN[$2]};      	      	              # fallback into english
      fi
   fi

   for (( i=3; $i <= $#; i++ )); do            		# substitute all message parameters
      p="${!i}"
      let s=$i-2
      s="%$s"
      msg=$(echo $msg | sed 's!'$s'!'$p'!')			# have to use explicit command name 
   done
   msg=$(echo $msg | perl -p -e "s/%[0-9]+//g" 2>/dev/null)     # delete trailing %n definitions
   local msgNum=$(cut -f 1 -d ':' <<< $msg)
   local severity=${msgNum: -1}
   local msgHeader=${MSG_HEADER[$severity]}
   echo "$msgHeader $msg"
}

# Write essage

function writeToConsole() {   # messagenumber
   local msg
   if [[ -z $DESIRED_LANGUAGE ]]; then		
		msg=$(getMessageText L $@)
   else
		msg=$(getMessageText $DESIRED_LANGUAGE $@)
   fi
		
   echo -e $msg
}

# Check if all required commands are available and set variables for commands with absolut pathes
# Variable names are identical to command names in uppercase
# Example: Absolute path of iwconfig will be available in variable IWCONFIG

function detectMods() {

	MODS="PING DIG IP EGREP AWK IFCONFIG IWCONFIG IWLIST SED LSUSB GREP PERL ROUTE ARP"  # required commands

	for mod in $MODS; do
		lwr=$(echo $mod | tr '[:upper:]' '[:lower:]')
		p=$(find {/sbin,/usr/bin,/usr/sbin,/bin} -name $lwr | head -n 1)
		eval "$mod=\"${p}\""
		if [[ -z $p ]]; then
			if [ -z "$MODS_MISSING_LIST" ]; then
				MODS_MISSING_LIST=$lwr
			else
				MODS_MISSING_LIST="$MODS_MISSING_LIST $lwr"
			fi
			MODS_MISSING=1
		fi
	done

	declare -A REQUIRED_PACKET_MAP=([iwconfig]=wireless-tools [iwlist]=wireless-tools [lsusb]=usbutils [dig]=dnsutils)
	declare -A USED_PACKET_MAP=()

	for p in $MODS_MISSING_LIST; do
		needed_package=${REQUIRED_PACKET_MAP[$p]}
		if [ -z "$required_packages" ]; then		
			required_packages=$needed_package
		else
			if [ ! ${USED_PACKET_MAP[$needed_package]+_}  ]; then			
				required_packages="$required_packages $needed_package"
			fi
		fi
		eval USED_PACKET_MAP[$needed_package]="1"							
	done

	if (( $MODS_MISSING )); then
		writeToConsole $MSG_MISSING_COMMANDS "$MODS_MISSING_LIST"
		writeToConsole $MSG_APT_HINT "$required_packages"
		if (( ! $SKIP_MODULES )); then
			writeToConsole $MSG_ENABLE_RUN_WITH_MISSING_PACKAGES
			exit 127
		fi
	fi

}


# Masquerade wireless key in /etc/network/interfaces

function masqueradeWirelessKey() {
	$SED 's/\(wireless-key.*\"\)[^\"\]\+/\1@@@@@@@@/g'
}

# Masquerade psk in /etc/wpa_supplicant/wpa_supplicant.conf

function masqueradePsk() {
	$SED 's/\(psk.*\"\)[^\"\]\+/\1@@@@@@@@/g'
}

# Masquerade IPV6 address

function masqueradeIPV6() {
	$SED 's/\(\([a-fA-F0-9\]\)\{4\}\(:\|::\)\)\{1,7\}\([a-fA-F0-9\]\)\{4\}/@:@:@:@:@:@:@:@/'
}

# Masquerade ssids in wpa_supplicant

function masqueradeSSIDinWPA() {
	$SED 's/\(ssid.*\"\)[^\"\]\+/\1@@@@@@@@/g'
}

# Masquerade SSID

function masqueradeSSID() {
	if [[ -n $SSID ]]; then
		$SED "s/$SSID/@@@@@@@@/g"
	else
		$SED ""
	fi
}

# Masquerade MAC

function masqueradeMAC() {
	$PERL -pe "s/((?:[a-zA-Z0-9]{2}[:-]){3})((?:[a-zA-Z0-9]{2}[:-]){2}[a-zA-Z0-9]{2})/\1\@@\:@@\:@@/g" 2>/dev/null
}

# Masquerade external IP addresses

function masqueradeIPs() {
	
$PERL -ne '
	my $IP_ADDRESS = qr /(([\d]{1,3}\.){3}[\d]{1,3})/;
	my $line;

	$line=$_;
	while ($line =~ /($IP_ADDRESS)/g ) {

			my $ip = $1;

			if ( $1 !~ /^192\.168\./
				&& $1 !~ /^127\./
				&& $1 !~ /0\.0\.0\.0/
				&& $1 !~ /255\.{1,3}(255)?/
				&& $1 !~ /^169\./
				&& $1 !~ /^10\./
				&& $1 !~ /^172\.([1][6-9]|2[1-9]|3[0-1])/ ) {
					my $privateIp = $ip;
					$privateIp =~ s/\d+\.\d+/%%%.%%%/;
					s/$ip/$privateIp/;
			}
		 }
		 
	print;
	' 2>/dev/null
}

# Check for valid chars in SSID according IEEE 802.11

function checkSSID() {

$PERL -e '
	# IEEE 802.11 
	# 7.3.2.1 Service Set Identity (SSID) element
	my $s=$ARGV[0];
	if (
	  	  ($s =~ /[?\"\$\[\\\]\+]/) 		# invalid all the time 
		 || ($s =~ /^[!#;]/)				# invalid if leading
		 || ($s =~ /[\x00-\x1F]/)		   # non printable character
		 || ($s =~ /[\x80-\xFF]/)		   # extended characters >= 0x80
	   ) {
	  	  exit 1;
			}
	else	{
	  	  exit 0;
			}
	' $SSID 2>/dev/null
   return $?

}

# Invoke script against multiple Pis to check script against raspbian

function testMyself() { # invocationparms

	HOSTS="raspifix"
	EXT="sh"
	
	for host in $HOSTS; do
		echo "*** Executing script on $host"
		ssh pi@$host rm -f /home/pi/raspiNetInfo.$EXT > $host.log		
		scp -p raspiNetInfo.$EXT pi@$host: > /dev/null		
		ssh pi@$host "/home/pi/raspiNetInfo.$EXT $1" >> $host.log		
		cat $host.log
		echo
		echo "--------------------------------------------------------------------------------------------------------------------"
		echo
	done
	exit 0
}

# Print help text

function usage() {
   echo "$MYSELF $VERSION (CVS Rev $CVS_REVISION_ONLY - $CVS_DATE_ONLY)" 
   echo "$LICENSE"
   writeToConsole $MSG_USAGE
   exit 0
}

function ipChecks() {

	dev=$(ifconfig | grep eth | cut -f 1)
	if ! ifconfig | grep -A 2 eth | grep -qi "inet ad"; then
		writeToConsole $MSG_NO_IP_ASSIGNED "$dev"
	fi

	if (( ! $ETHERNET_ONLY )); then
		if ! ifconfig | grep -A 2 wlan | grep -qi "inet ad"; then		
			dev=$(ifconfig | grep wlan | cut -f 1)
			writeToConsole $MSG_NO_IP_ASSIGNED "$dev"
		fi
	fi	
}

# Check whether ping of IPs of google is possible

function pingChecks() {
	local IP
	local PING_RES
	local C

	MY_IPS="8.8.8.8"

	IP_PING_OK=0
	for IP in $MY_IPS; do
		if $PING -c 3 -W 10 $IP 2>&1 2>&1 1>/dev/null; then
			IP_PING_OK=1
			break	  
		fi
	done

	if (( $IP_PING_OK )); then
		writeToConsole $MSG_PING_OK $IP
	else
		writeToConsole $MSG_PING_FAILED $IP
	fi

	DNSNAME_PING_OK=0
	MY_DNS="www.google.com"

	if $PING -c 3 -W 3 $MY_DNS 2>&1 | $GREP " 0%" 2>&1 1>/dev/null; then
		writeToConsole $MSG_PING_OK $MY_DNS
		DNSNAME_PING_OK=1			
	else
		writeToConsole $MSG_PING_FAILED $MY_DNS
	fi
return
}

# Check gateway

function gatewayChecks() {
				
	defaultGateway=$($ROUTE -n | $AWK '/^[0]+\.[0]+\.[0]+\.[0]+/ { print$0; } ')
	if [[ -z $defaultGateway ]]; then
		writeToConsole $MSG_NO_STD_GATEWAY_DEFINED
	fi

}

# Check nameserver

function nameserverChecks() {

	local res
	
	if [ ! -e /etc/resolv.conf ]; then
		writeToConsole $MSG_MISSING_RESOLV_CONF
		return
	fi

	nameserver=$($EGREP -v "^(#|$)" /etc/resolv.conf | $GREP -i "nameserver" )
	if [[ -z $nameserver ]]; then
		writeToConsole $MSG_MISSING_DNS
		return
	fi
		
	ip=$($EGREP -v "^(#|$)" /etc/resolv.conf | $AWK '/nameserver/ { print $2; exit}')
	if ! (ping -c 3 -W 3 $ip 2>&1 | $GREP " 0%") 2>&1 >/dev/null; then
		writeToConsole $MSG_DNS_NOT_REACHABLE $ip
	else
		if [ "$DIG" != "" ]; then
			if ! $DIG @$ip www.google.com +noques +nostats +time=1 | $EGREP -v "^;|^$" | $EGREP "IN.*A" >/dev/null; then
				writeToConsole $MSG_INVALID_DNS
			fi
		else
			writeToConsole $MSG_SKIPPING_TEST "dig"
		fi		 
	fi
	
}

# Check SSID

function SSIDChecks() {
	AP_FOUND=0														
	if [[ -n $SSID ]]; then
		if [ -n "$IWLIST" ]; then
			if ! ($IWLIST wlan0 scanning | $GREP -c "ESSID.*$SSID") 2>&1 >/dev/null; then	
				writeToConsole $MSG_AP_WITH_SSID_NOT_FOUND
			else
				AP_FOUND=1
			fi
		
			if ! checkSSID; then
				writeToConsole $MSG_SSID_INVALID
			fi
		else
			writeToConsole $MSG_SKIPPING_TEST "iwlist"
		fi
	fi

}

# Print some details from iwlist scanning for passed SSID
# Example: Passed SSID is foo
# iwlist output is as follows
#					Protocol:IEEE 802.11bgn
#					Frequency:2.432 GHz (Channel 5)
#					IE: IEEE 802.11i/WPA2 Version 1
#						Group Cipher : CCMP
#						Pairwise Ciphers (1) : CCMP
#						Authentication Suites (1) : PSK
#					Signal level=92/100  

function listAPDetails() {
	if [ -n "$IWLIST" ]; then
		echo "--- iwlist for SSID"
		$IWLIST wlan0 scanning 2>&1 | $AWK "\$1 ~ /$SSID/ { ssid=1 } /Cell/ { ssid=0 } ssid == 1 && /Protocol|Channel|WPA|Cipher|Auth|Signal|ESSID/{ print }" | masqueradeSSID
	else
		writeToConsole $MSG_SKIPPING_OUTPUT "iwlist"
	fi	
}

#############################################
# Check for typical config errors
#############################################

function checkConfig() { 

	pingChecks
	
	if (( ! $IP_PING_OK )); then
		ipChecks
	fi
	SSIDChecks
	nameserverChecks
	gatewayChecks
	
}

###################################
# Print network information
###################################

function collectInfo() {
	
	# Info useful for wirelsss and wired
	
	echo "--- uname -a" 
	uname -a

	echo '--- ip a s'
	$IP a s 2>&1 | masqueradeMAC | masqueradeIPV6 | masqueradeSSID  
	
	if [ -e /etc/resolv.conf ]; then
		echo '--- grep -i "nameserver" /etc/resolv.conf'
		$EGREP -v "^(#|$)" /etc/resolv.conf | $GREP -i "nameserver" | masqueradeIPs
	fi
	
	echo "--- /etc/network/interfaces"
	$EGREP -v "^(#|$)|::" /etc/network/interfaces | masqueradeSSID | masqueradeWirelessKey
	
	echo "--- /etc/hosts"
	$EGREP -v "^(#|$)|::" /etc/hosts | masqueradeIPs
	
	echo '--- ip r s'
	$IP r s | masqueradeIPs
	
	echo '--- ip n s'
	$IP n s | masqueradeIPs | masqueradeMAC

	echo '--- ip r g 8.8.8.8'
	$IP r g 8.8.8.8 | masqueradeIPs | masqueradeMAC
	
	echo '--- route -n'
	$ROUTE -n | masqueradeIPs

	echo '--- arp -av'
	$ARP -av | masqueradeIPs | masqueradeMAC
	
	# Info useful for wireless only
	
	if [[ -n $SSID ]]; then	
			if [ "$LSUSB" != "" ]; then
				echo '--- lsusb | grep -v "root hub" | grep -i "wire"'
				$LSUSB | $GREP -v "root hub" | $GREP -i "wire"
			else
				writeToConsole $MSG_SKIPPING_OUTPUT "lsusb"
			fi

		if [ -n "$IWCONFIG" ]; then		
			echo "--- iwconfig (eth und wlan)"
			$IWCONFIG 2>&1 | $GREP -v "no wireless" | $AWK '/^(eth|wlan)/ { ifc=$1 } !NF { ifc="" } ifc { print }' | $EGREP -vi "(retry|power|rate)" | masqueradeSSID | masqueradeMAC
		
			if $IWCONFIG wlan0 2>/dev/null | $GREP Nickname 1>/dev/null; then			# iwlist scanning only useful if there was a wlan if found
		
				echo "--- iwlist scanning"
				$IWLIST wlan0 scanning | $EGREP -i "(chan|signal)" 2>/dev/null 
	
				if (( $AP_FOUND )); then								# if there was an AP found with the SSID print other info
					listAPDetails
				fi
			fi
		else
			writeToConsole $MSG_SKIPPING_OUTPUT "iwconfig"
		fi

		# Infos for wpa_supplicant

		if [ -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then		
			echo '--- /etc/wpa_supplicant/wpa_supplicant.conf'

			sudo $EGREP -v "^(#|$)" /etc/wpa_supplicant/wpa_supplicant.conf | masqueradeMAC | masqueradeIPV6 | masqueradeSSIDinWPA | masqueradePsk
			if [[ -e /var/log/messages ]]; then
				echo '--- grep wpa /var/log/messages | tail -n 15'
				sudo grep wpa /var/log/messages | tail -n 15 | masqueradeMAC | masqueradeIPV6 | masqueradeSSID | masqueradePsk
			else
				echo "--- journalctl --system -xe | grep wpa | tail -n 15"
				journalctl --system -xe | grep wpa | tail -n 15 | masqueradeMAC | masqueradeIPV6 | masqueradeSSID | masqueradePsk
			fi
		fi
	fi
	
}

################
# *** Main *** #
################

TEST=0														
SSID=""														
opt=$@
ETHERNET_ONLY=0												
SKIP_MODULES=0												
NO_XLATION=0
DESIRED_LANGUAGE=""

# Parse arguments
while getopts ":e :g :l: :h :m :s: :t" opt; do
   case "$opt" in
		h) usage 0
			;;
		t) TEST=1
			;;   
		g) NO_XLATION=1
			;;
		e) ETHERNET_ONLY=1
			;;
		m) SKIP_MODULES=1
			;;
		s) SSID=$OPTARG
			ETHERNET_ONLY=0
			;;
		l) DESIRED_LANGUAGE=$OPTARG
			;;
		\?) writeToConsole $MSG_UNKNONW_OPTION $OPTARG
			usage 127
			;;
		:) writeToConsole $MSG_OPTION_REQUIRES_ARGS $OPTARG
			usage 127
			;;
	esac
done

echo "$LICENSE"

detectMods

if [[ -z $SSID && $ETHERNET_ONLY -eq 0 ]]; then
	writeToConsole $MSG_MISSING_MANDATORY_PARM					# either -e or -s SSID mandatory
	exit 127
fi

# Do your job

if (( $TEST )); then									
	args=$(echo $@ | sed 's/-t//')								# strip test flag for testMyself
	testMyself "$args"
else
	echo "[spoiler][code]"
	echo "$GIT_CODEVERSION"
	writeToConsole $MSG_STARTING_DATA_COLLECTION
	checkConfig													
	collectInfo													
	writeToConsole $MSG_CHECK_OUTPUT $LOG_FILE
	echo "[/code][/spoiler]"
fi	

# vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab:syntax=sh 
