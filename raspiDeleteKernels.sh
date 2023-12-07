#!/bin/bash

# ls -1 /boot | grep -v -E $(uname -m | sed -E 's/arm(v[0-9]+)l?/\1/') | grep -E "^(config-|initrd|System\.map)" | xargs -0 echo

# kernel.img is 32-bit for BCM2835 (RPi1, B+ & Zero)
# kernel7.img is 32-bit for BCM2836 (RPi2B) and BCM2837 (RPi3iA & RPi3B & RPi3B+)
# kernel7l.img is 32-bit for BCM2711 (RPi4B)
# kernel8.img is 64-bit for BCM2837 (RPi3A, 3B, 2A, 3B+) or BCM2711 (RPi4)

