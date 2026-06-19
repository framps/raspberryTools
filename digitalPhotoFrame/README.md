# Simple digital picture frame to display photos and videos on a RaspberryPi Zero 2W

## Function

Displays photos and videos on a monitor and provides a simple Python HTTP app, which allows to upload
photos and videos from a mobile or Laptop per drag n drop. 

### Note

The upload app should be used in a local secure environment only !

## Required HW and SW

### HW

1. RaspberryPi Zero 2W
1. SD card with enough space, i.e. 32GB
1. Any monitor which has a HDMI input port
1. Power supply for the monitor
1. Either a power supply for the RPi Zero or at least two USB 2.0 ports which can be bundled with a Y cable to power the RPi Zero

### SW

1. RaspberryOS lite
1. mpv


## Installation

1. Make a directory /opt/pictureViewer and change the owner to user pi
1. Copy pictureViewer.sh and pictureUpload.py into /opt/pictureViewer
1. Copy both *.service files into /etc/systemd/system
1. Update the photo location in pictureViewer.sh and pictureUpload.py if needed. Default is /photos.
1. Enable both services
   1. `sudo systemctl enable pictureViewer.service`
   1. `sudo systemctl enable pictureUpload.service`
   1. `sudo systemctl start pictureViewer.service`
   1. `sudo systemctl start pictureUpload.service`

