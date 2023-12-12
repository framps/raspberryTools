#!/bin/bash

# ls -1 /boot | grep -v -E $(uname -r | sed -E 's/arm(v[0-9]+)l?/\1/') | grep -E "^(config-|initrd|System\.map)" | xargs -0 echo

# kernel.img is 32-bit for BCM2835 (RPi1, B+ & Zero)
# kernel7.img is 32-bit for BCM2836 (RPi2B) and BCM2837 (RPi3iA & RPi3B & RPi3B+)
# kernel7l.img is 32-bit for BCM2711 (RPi4B)
# kernel8.img is 64-bit for BCM2837 (RPi3A, 3B, 2A, 3B+) or BCM2711 (RPi4)

# vmlinuz-6.1.0-rpi4-rpi-v6
# vmlinuz-6.1.0-rpi4-rpi-v7
# vmlinuz-6.1.0-rpi4-rpi-v7l
# vmlinuz-6.1.0-rpi4-rpi-v8
# vmlinuz-6.1.0-rpi6-rpi-v6
# vmlinuz-6.1.0-rpi6-rpi-v7
# vmlinuz-6.1.0-rpi6-rpi-v7l
# vmlinuz-6.1.0-rpi7-rpi-v6
# vmlinuz-6.1.0-rpi7-rpi-v7
# vmlinuz-6.1.0-rpi7-rpi-v7l


# script to remove kernel package(s), given kernel(s)  

# given vmlinuz-6.1.0-rpi6-rpi-v7
# 	do: 
# sudo apt purge linux-image-6.1.0-rpi6-rpi-v7

#for krnl in $@
#do
#	pkg=linux-image${krnl#vmlinuz}
#	echo "#" Removing package $pkg for kernel $krnl
#	sudo apt purge $pkg
#done
#
#sudo apt autoremove

sudo apt-cache search "linux-image-" | grep -v -E "dbg|header|meta" | grep rpi

uname -r
6.1.0-rpi7-rpi-v8
sudo apt purge linux-image-6.1.0-rpi6-rpi-2712
ls /boot # kernel no longer there
sudo apt install linux-image-6.1.0-rpi6-rpi-2712
ls /boot # kernel is there again

#linux-images.img-6.1.0-rpi6-rpi-2712
#linux-images.img-6.1.0-rpi6-rpi-v8
#linux-images.img-6.1.0-rpi7-rpi-2712

# ls -1 /boot | grep -v -E $(uname -r) | grep -E "^initrd" | sed 's/initrd/linux-image/; s/\.img//' | xargs echo | tee kernels.lst; sudo mv kernels.lst /boot
