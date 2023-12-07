#!/bin/bash

# ls -1 /boot | grep -v -E $(uname -m | sed -E 's/arm(v[0-9]+)l?/\1/') | grep -E "^(config-|initrd|System\.map)" | xargs -0 echo

# kernel.img is 32-bit for BCM2835 (RPi1 & Zero)
# kernel7.img is 32-bit for BCM2836 (RPi2) and BCM2837 (RPi3)
# kernel7l.img is 32-bit for BCM2711 (RPi4)
# kernel8.img is 64-bit for BCM2837 (RPi3) or BCM2711 (RPi4)

