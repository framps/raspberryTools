#!/usr/bin/env python

"""\
#######################################################################################################################
#
#	SMSRelay server - Script to receive SMS on a Raspberry Pi as a service and forward them in an eMail to an SMS receiver eMail.
#
#	Should be started a systemd daemon. Initially gammu-smsd was used to relay SMS but given the fact gammu-smsd is
#	unreliable gsmmodem is used.
#
#	For testing purposes of the SMS Relay Server an SMS *ping will send a ping eMail to the system admin.
#
#######################################################################################################################
#
#    Copyright (c) 2021 framp at linux-tips-and-tricks dot de
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
"""

from __future__ import print_function

import logging
import smtplib
import socket
import sys
from datetime import datetime
from gsmmodem.modem import GsmModem

PORT = '/dev/ttyUSB2'
BAUDRATE = 115200
PIN = None # SIM card PIN (if any)
SMTP_SENDER = 'admin@dummy.com'		# EMailProvider inBox User
PING_RECEIVER = SMTP_SENDER			# and admin who receives a ping eMail
EMAIL_SENDER = 'sender@dummy.com'	# Sender eMail 
SMS_RECEIVER = 'smsrelay@dummy.com'	# eMail which receives any SMS
TARGET_PHONE = "+4947114712"		# phone number the SMS is sent to
LOG_FILE = "/home/pi/smsrelay/smsrelay.log"

#sys.stdout = open(LOG_FILE, 'a', 0)

def handleSms(sms):
    print(datetime.now())
    print(u'== SMS message received ==\nFrom: {0}\nTime: {1}\nMessage:\n{2}\n'.format(sms.number, sms.time, sms.text))

    hostName=socket.gethostname()

    if sms.text == "*ping":
        receivers = [ PING_RECEIVER ]
    else:
        receivers = [ SMS_RECEIVER ]

    sourcePhone = sms.number

    text = sms.text
    subject = u'"{0}{1}"'.format(sms.text[:20], '...' if len(sms.text) > 20 else '')

    message = """From: SMSRelay <""" + SMS_RECEIVER + """>
To: SMSRelayUser <""" + receivers[0] + """>
Subject: """ + subject + """

Dear SMSRelayUser

I just received following SMS from """ + sourcePhone + """ for """ + TARGET_PHONE + """ which I forward to you:

--- START SMS ---
"""+text+"""
---  END SMS  ---

Hope you enjoy my service.

Regards

Your SMS relay server on """ + hostName + """."""

    try:
        smtpObj = smtplib.SMTP('localhost')
        smtpObj.sendmail(EMAIL_SENDER, SMTP_SENDER, message)
        print("Successfully sent email to " + receivers[0])
    except SMTPException:
        print ("Error: unable to send email to " + receivers[0])

def main():
    print(datetime.now())
    print('Initializing modem to ' + PORT + ' ...')
    # Uncomment the following line to see what the modem is doing:
    # logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.DEBUG)
    modem = GsmModem(PORT, BAUDRATE, smsReceivedCallbackFunc=handleSms)
    modem.smsTextMode = False
    modem.connect(PIN)
    print('Waiting for SMS message...')
    try:
        modem.rxThread.join(2**31) # Specify a (huge) timeout so that it essentially blocks indefinitely, but still receives CTRL+C interrupt signal
    finally:
        modem.close()

if __name__ == '__main__':
    main()
