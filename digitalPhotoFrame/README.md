# Simple digital picture frame to display photos and videos on a RaspberryPi Zero 2W

## Function

Displays photos and videos on a monitor and provides a simple Python HTTP app, which allows to upload
photos and videos from a mobile or Laptop per drag n drop.

### Note

This toolset should be used in a local secure environment only !

## Required HW and SW

### HW

1. RaspberryPi Zero 2W
1. SD card with enough space, i.e. 32GB
1. Any monitor which has a HDMI input port
1. Power supply for the monitor
1. Either a power supply for the RPi Zero or at least two USB 2.0 ports which are bundled with a Y cable to power the RPi Zero

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

## Reduce memory consumption

The PiZero has 512MB RAM only. Therefore some additional configuration is suggested.
1. Special section in /boot/firmware/cmdline.txt to turn off unused services and define the used GPU memory for a PIZero
   ```
   # pizero 2w settings 
   [board-type=0x902120]
   dtoverlay=disable-bt
   dtparam=krnbt=off
   dtparam=act_led_trigger=non
   disable_poe_fan
   gpu_mem=64
   ```
2. Turn of systemd logging with raspi-config
   
## Upload photos and videos

1. The digital photo frame will get an IP with DHCP from the local network router. Check your local router for the IP.
2. Open this IP with port 8080 (`http:/<ip>:8080`) and select or drop the pictures and photos to upload
