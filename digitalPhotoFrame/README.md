# Simple digital picture frame to display photos and videos on a RaspberryPi Zero 2W

## Function

Displays photos and videos on a monitor and provides a simple Python HTTP app, which allows to upload
photos and videos from a mobile or Laptop per drag n drop.

### Note

This toolset should be used in a local secure environment only !

## Required HW and SW

### HW

1. RaspberryPi Zero 2W
1. SD card with enough space, for example 32GB
1. Any monitor which has a HDMI input port and optionally two USB 2.0 ports
1. Power supply for the monitor
1. Either a dedicated power supply for the RPi Zero or two USB 2.0 ports availabel on the monitor which are bundled with a Y cable to power the RPi Zero

### SW

1. RaspberryOS lite
1. mpv

## Installation

1. Create a directory /opt/pictureViewer
1. Copy pictureViewer.sh and pictureUpload.py into /opt/pictureViewer
1. Copy both *.service files into /etc/systemd/system
1. Update the photo location in pictureViewer.sh and pictureUpload.py if needed. Default is /photos.
1. Make user pi owner of /photos directory
1. Enable and start both services
   1. `sudo systemctl enable pictureViewer.service`
   1. `sudo systemctl enable pictureUpload.service`
   1. `sudo systemctl start pictureViewer.service`
   1. `sudo systemctl start pictureUpload.service`
## Upload photos and videos

1. The digital photo frame will get an IP with DHCP from the local network router. Check your local router for the IP.
2. Open this IP with port 8080 (`http:/<ip>:8080`) and select or drop the pictures and photos to upload
