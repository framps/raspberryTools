#!/bin/bash
#
# Retrieve total number of bytes written on SD card root filesystem.
# Is useful to get some idea about the probability the SD card will die.
#
sudo dumpe2fs -h /dev/mmcblk0p2 | grep -i "lifetime writes"
