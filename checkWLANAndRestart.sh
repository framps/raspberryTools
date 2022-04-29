#!/bin/bash
#
#######################################################################################################################
#
#   Check whether there exists a network connection to the local router
#   and restart interface. If then there is still no connection restart the server
#
#   Usually used in crontab for an unattended Raspberry
#
#   Copyright (C) 2017 framp at linux-tips-and-tricks dot de
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#######################################################################################################################

DEBUG=0                       # if 1 just echo commands, if 0 execute commands

(( $DEBUG )) && EXEC="echo"

# retrieve router IP

function getRouterIP() {
   echo "$(/sbin/ip route show to 0/0 | /usr/bin/awk '{ print $3 }' | /usr/bin/head -1l)"
}

# restart network interface

function netRestart() {
   /usr/bin/logger "keine Netzwerkverbindung, wlan0 neustarten"
   $EXEC sudo /sbin/ifdown 'wlan0'
   sleep 60
   $EXEC sudo /sbin/ifup --force 'wlan0'
   echo "!!"
   sleep 15
}

# reboot server

function reboot() {
   /usr/bin/logger "keine Netzwerkverbindung, wlan0 neustarten erfolglos, Reboot"
   $EXEC sudo /sbin/shutdown -r now
}

# test if IP is valid (dd.dd.dd.dd)

function isValidIP() { # IP
   grep -q -E "^([[:digit:]]+\.){3}[[:digit:]]+$" <<< "$1"
   return $?
}

### main ###

IP=$(getRouterIP)                            # retrieve router IP
if isValidIP "$IP"; then                     # valid router IP found ?
                                             # yes
   if ! /bin/ping -c2 $IP > /dev/null; then  # can router be pinged ?
                                             # no
      netRestart                             # restart interface
      IP=$(getRouterIP)                      # retrieve router IP after restart
      if isValidIP "$IP"; then               # is new IP valid ?
                                             # yes
         if ! /bin/ping -c2 "$IP" > /dev/null; then # can router now be pinged ?
                                             # no
            reboot                           # then reboot
       # else
                                             # router can be pinged after interface restart, just exit
         fi
      else
                                             # new IP not valid
         reboot                              # reboot
      fi
 # else
                                             # router can be pinged
                                             # just exit
   fi
else
                                             # no valid router IP found
   reboot                                    # reboot
fi
