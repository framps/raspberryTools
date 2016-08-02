#!/bin/bash
#####################################################################################################
#
# Works for raspberry SD cards and OS only (raspbian, raspbmc, ...)
#
# --- Purpose:
# Copy user data partition from SD card to another partition (e.g. USB stick or external USB disk)
# and update required files such that from now on the other partition will be used by raspberry
# and SD card is only needed for raspberry boot process 
#
# 1) Valid candidates for new data partition:
#    a) filesystem type has to match
#    b) target filesystem has to have enough space
#    c) target filesystem has to be empty
# 2) Backup SD card boot command file cmdline.txt to cmdline.txt.sd
# 3) Update SD card boot command file cmdline.txt to use the new partition from now on
# 5) Copy all files from SD data partition /dev/mmcblk0p2 to target partition
# 6) Update /etc/fstab file on target partition
#
# --- Notes:
# 1) No data is deleted from any partition in any case
# 2) If something went wrong the backuped file cmdline.txt.sd on /dev/mmcblk0p1 can be 
#    copied to cmdline.txt and the original SD data partition will be used again on next boot
#
#####################################################################################################
#
#    Copyright (C) 2013-2016 framp at linux-tips-and-tricks dot de
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
#####################################################################################################

# constants

VERSION="V0.1.5"
MYSELF="${0##*/}"
SSD_PARTITION="/dev/mmcblk0p"
BOOT_PARTITION="${SSD_PARTITION}1"
DATA_PARTITION="${SSD_PARTITION}2"
SRC="/tmp/src"
TGT="/tmp/tgt"
CMD_FILE="cmdline.txt"
LOG_FILE=${MYSELF/.sh/}.log
rm -f $LOG_FILE 1>/dev/null 2>&1
exec 1> >(tee -a $LOG_FILE >&1)
exec 2> >(tee -a $LOG_FILE >&2)

LANG_EXT=`echo $LANG | tr '[:lower:]' '[:upper:]'`
LANG_SUFF=${LANG_EXT:0:2}
if [[ $LANG_SUFF != "DE" ]]; then
     	LANG_SUFF="EN" 
fi

MSG_VERS_DE='--- %1 %2 ---'
MSG_VERS_EN='--- %1 %2 ---'
MSG_ROOT_DE='!!! Script muss als root aufgerufen werden'
MSG_ROOT_EN='!!! Script has to be called as root'
MSG_NOBOOT_DE='!!! Bootpartition %1 der raspi nicht gefunden'
MSG_NOBOOT_EN='!!! No boot partition %1 of raspi found'
MSG_BOOTINVAL1_DE='!!! Bootdatei %1 nicht auf Bootpartition %2 gefunden'
MSG_BOOTINVAL1_EN='!!! Bootfile %1 not found on boot partition %2'
MSG_BOOTINVAL2_DE='!!! Format der Bootdatei %1 auf Bootpartition %2 ungültig'
MSG_BOOTINVAL2_EN='!!! Bootfile format of %1 on boot partition %2 invalid'
MSG_MULTIDISK_DE='!!! Nur eine der USB Platten %1 darf angeschlossen sein'
MSG_MULTIDISK_EN='!!! Only one of the USB disks %1 should be connected'
MSG_CURCFG_DE='--- Datenpartition %1 hat %2 GB und Filesystemtyp %2'
MSG_CURCFG_EN='--- Data partition %1 has %2 GB and filesystemtype %3'
MSG_NODATA_DE='!!! Datenpartition %1 der raspi nicht gefunden'
MSG_NODATA_EN='!!! No data partition %1 of raspi found'
MSG_SELECT_DE='--- Welche Datenpartition soll benutzt werden (1-%1)'
MSG_SELECT_EN='--- Select new user partition (1-%1)'
MSG_AVAIL_DE='--- Mögliche neue Datenpartitionen'
MSG_AVAIL_EN='--- Candidates for data partition'
MSG_SURE_DE='--- Soll %1 wirklich ab sofort von der SD Karte benutzt werden [j/N]' 
MSG_SURE_EN='--- Are you sure the SD card should use %1 from now on [y/N]' 
MSG_NOFOUND_DE='!!! Keine möglichen Datenpartitionen gefunden.'
MSG_NOFOUND_EN='!!! No possible data partitions found'
MSG_NOFREE_DE='!!! Neue Datenpartition muss leer und wenigstens %1 GB haben.'
MSG_NOFREE_EN='!!! New data partition has to be empty and has to have at least %1 GB'
MSG_ABORT_DE='!!! Programmabbruch'
MSG_ABORT_EN='!!! Program aborted'
MSG_MOUNT_DE='--- Verbinde %1 und %2...'
MSG_MOUNT_EN='--- Mounting %1 and %2...'
MSG_COPY_DE='--- Kopiere die alte Datenpartition %1 auf die neue Partition %2. Bitte Geduld ...'
MSG_COPY_EN='--- Copy old data partition %1 to new partition %2. Be patient ...'
MSG_SKIPCOPY_DE='!!! Alte Datenpartition wird nicht kopiert da neue Partition schon eine Raspi Datenpartition enthaelt'
MSG_SKIPCOPY_EN='!!! Old data partition is not copied because the new partition already has a Raspi data partition'
MSG_FSTAB_DE='--- Die neue fstab wird angepasst'
MSG_FSTAB_EN='--- Updating new fstab'
MSG_BUFND_DE='--- Backup von %1 existiert schon'
MSG_BUFND_EN='--- Backup of %1 already exist'
MSG_BUCMD_DE='--- Backup von %1 auf %2 wird erstellt'
MSG_BUCMD_EN='--- Creating backup of %1 on %2'
MSG_UPDCMD_DE='--- Boot file %1 wird angepasst für %2'
MSG_UPDCMD_EN='--- Updating boot file %1 with %2'
MSG_CLEANUP_DE='--- Aufräumarbeiten'
MSG_CLEANUP_EN='--- Cleanup'
MSG_DEPRECATED_DE='>>> Shell Version von raspiSD2USB ist alt und wird nicht mehr gewartet. Wenn möglich die aktuelle Pythonversion raspiSD2USB.py benutzen'
MSG_DEPRECATED_EN='>>> Shell version of raspiSD2USB is old and is not maintained any more. Please use the Python version raspiSD2USB.py if possible'

# helper to write messages in English or German depending on the active locale

function writeMessage { # id 
	local id msg i firstChar s p
	id=$(echo "MSG_$1_$LANG_SUFF" | tr '[:lower:]' '[:upper:]')
	msg="${!id}"
	if [[ -z $msg ]]; then
		msg="$1 "
		for (( i=2; $i <= $#; i++ )); do  	      	
			msg="$msg ${!i}"
		done
	else
		for (( i=2; $i <= $#; i++ )); do  
	      		p="${!i}"
		      	let s=$i-1
	      		s="%$s"
	      		msg=`echo $msg | sed 's!'$s'!'$p'!'`
	   	done
	   	msg=$(echo $msg | sed "s/%[0-9]+//g") 
	fi
	firstChar=${1:0:1}
	if [[ $firstChar =~ [a-z] ]]; then
		msg="${msg}\x20"
		echo -ne $msg
	else
		echo $msg 
	fi
}

function listCurrentConfig() {

	mkdir -p $SRC 1>/dev/null 2>&1
	mount $BOOT_PARTITION $SRC 1>/dev/null 2>&1
	if [[ ! -f $SRC/$CMD_FILE ]]; then
		writeMessage "BOOTINVAL1" $CMD_FILE $BOOT_PARTITION 
		cleanup
		exit -1
	fi

	cmdLine=$(cat $SRC/$CMD_FILE)
	regex="root=(.*) .*rootfstype=([0-9a-zA-Z]+)"
	if [[ ! $cmdLine =~ $regex ]]; then
		writeMessage "BOOTINVAL2" $CMD_FILE $BOOT_PARTITION
		cleanup
		exit -1
	fi
	rootPartition=${BASH_REMATCH[1]}
	rootType=${BASH_REMATCH[2]}

	umount $BOOT_PARTITION 1>/dev/null 2>&1

	mkdir -p $SRC 1>/dev/null 2>&1
	mount $rootPartition $SRC 1>/dev/null 2>&1
	diskStatsSrc=$(df -T | grep $rootPartition)
	allocatedRootSrc=$(echo $diskStatsSrc | awk ' { printf "%.2f",$3/1024/1024; }')
	umount $rootPartition $SRC 1>/dev/null 2>&1

	writeMessage "CURCFG" $rootPartition $allocatedRootSrc $rootType

}

writeMessage "VERS" $MYSELF $VERSION

if (( $UID != 0 )); then
 	writeMessage "ROOT"
	exit -1
fi 

function cleanup {
   umount $SRC 1>/dev/null 2>&1
   umount $TGT 1>/dev/null 2>&1
   rmdir -p $SRC 1>/dev/null 2>&1
   rmdir -p $TGT 1>/dev/null 2>&1
}

# register cleanup 

function trapcleanup {
	writeMessage "CLEANUP"
	cleanup
	exit
}

trap 'trapcleanup' SIGHUP SIGINT SIGPIPE SIGTERM

# check whether xbmc partitions exist 

writeMessage "DEPRECATED" $BOOT_PARTITION

xbmcDisk=$(sfdisk -l 2>/dev/null | grep $BOOT_PARTITION )
if [[ -z $xbmcDisk ]]; then
	writeMessage "NOBOOT" $BOOT_PARTITION
	cleanup
	exit -1
fi
xbmcDisk=$(sfdisk -l 2>/dev/null | grep $DATA_PARTITION )
if [[ -z $xbmcDisk ]]; then
	writeMessage "NODATA" $DATA_PARTITION
	cleanup
	exit -1
fi

listCurrentConfig

# find possible available partitions

mkdir -p $SRC 1>/dev/null 2>&1
mount $DATA_PARTITION $SRC 1>/dev/null 2>&1
diskStatsSrc=$(df -T | grep $DATA_PARTITION)
allocatedSrc=$(echo $diskStatsSrc | awk ' { print $4; }')
umount $DATA_PARTITION $SRC 1>/dev/null 2>&1

srcFilesystem=$(blkid $DATA_PARTITION | awk ' { print $3; } ' | cut -d '"' -f 2)
otherDisks=$(fdisk -l | sed 's/*/ /' | awk '$1~"^/" { printf "%s %.2f\n", $1, $4/1024/1024; }')

partitionCandidatiechos=()
partitionCandidatesSize=()
IFS=$'\n'
for line in $otherDisks; do
	partition=$(echo $line | cut -f 1 -d ' ')
	size=$(echo $line | cut -f 2 -d ' ')

	if [[ ! $partition =~ $BOOT_PARTITION && ! $partition =~ $DATA_PARTITION ]]; then 
		tgtFilesystem=$(blkid $partition | awk ' { print $3; } ' | cut -d '"' -f 2)

		mkdir -p $TGT
		mount $partition $TGT 1>/dev/null 2>&1

		diskStatsTgt=$(df -T | grep $partition)
		freeTgt=$(echo $diskStatsTgt | awk ' { print $5; }')

		# check if enough space on target available

		if [[ ! -z $freeTgt ]]; then
			if (( $freeTgt < $allocatedSrc )); then
				continue
			fi
		fi

		# check if target is empty (ignore lost and found)

		diskFilesTgt=$(ls -la $TGT | wc -l)
		lostDir=$(ls -la $TGT | grep -i lost | wc -l)
		piHome=0
		[[ -d $TGT/home/pi ]] && piHome=1

		if (( $diskFilesTgt > 3 && ! (( $lostDir == 1 && $diskFilesTgt == 4 )) && ! (( $piHome)) )); then
			continue
		fi

		umount $partition 1>/dev/null 2>&1

		if [[ $tgtFilesystem == $srcFilesystem ]]; then
			partitionCandidates=("${partitionCandidates[@]}" $partition)
			partitionCandidatesSize=("${partitionCandidatesSize[@]}" $freeTgt)
		fi
	fi
done
unset IFS

# check if any partitions found

if (( ${#partitionCandidates[@]} == 0 )); then
	writeMessage "NOFOUND"
	writeMessage "NOFREE" $allocatedRootSrc
	exit -1
fi

# check that only one additional disk is attached

declare -A attachedDisks 
for p in ${partitionCandidates[@]}; do
	if [[ $p =~ ^(.*)([0-9]+)$ ]]; then
		name=${BASH_REMATCH[1]}
		attachedDisks[$name]=1
	fi
done

if (( ${#attachedDisks[@]} > 1 )); then
	disks=""
	for p in ${!attachedDisks[@]}; do
		disks="$disks,$p"
	done
	writeMessage "MULTIDISK" ${disks:1}
	exit -1
fi

# list possible targets and ask which target to use

writeMessage "AVAIL"
i=0
for p in "${partitionCandidates[@]}"; do
	echo "--- $(($i+1))) $p: $((${partitionCandidatesSize[$i]}/1024)) MB free"
	((i++))
done

maxIndex=${#partitionCandidates[@]}
selection=0
while (( $selection < 1 || $selection > $maxIndex )); do
	writeMessage "sELECT" $maxIndex
	read selection
	if [[ ! $selection =~ ^[0-9]+$ ]]; then
		selection=0
	fi
done

targetPartition=${partitionCandidates[$((selection-1))]}

# mount source and target partitions

writeMessage "MOUNT" $DATA_PARTITION $targetPartition
mkdir -p $SRC 
mkdir -p $TGT

mount $DATA_PARTITION $SRC 1>/dev/null 2>&1
mount $targetPartition $TGT 1>/dev/null 2>&1

diskStatsTgt=$(df -T | grep $targetPartition)
freeTgt=$(echo $diskStatsTgt | awk ' { print $5; }')

diskStatsSrc=$(df -T | grep $DATA_PARTITION)
allocatedSrc=$(echo $diskStatsSrc | awk ' { print $4; }')

# check if enough space on target available

if (( $freeTgt < $allocatedSrc )); then
	writeMessage "SPCERR" $(($allocatedSrc/1024)) $(($freeTgt/1024))
	cleanup
	exit -1
fi

# check if target is empty (ignore lost and found)

diskFilesTgt=$(ls -la $TGT | wc -l)
lostDir=$(ls -la $TGT | grep -i lost | wc -l)
piHome=0
[[ -d $TGT/home/pi ]] && piHome=1

if (( $diskFilesTgt > 3 && ! (( $lostDir == 1 && $diskFilesTgt == 4 )) && ! (( $piHome)) )); then
	writeMessage "NOTFREE" $targetPartition
	cleanup
	exit -1
fi

# check if on target there doesn't exist /home/pi already

if (( piHome )); then
	writeMessage "SKIPCOPY"
	cleanup
	exit -1
fi

# ask whether change should be started

writeMessage "SURE" $targetPartition
read answer
answer=${answer:0:1}	# first char only
answer=${answer:-"n"}	# set default no
YES="yYjJ"		# chars for yes
if [[ ! $YES =~ $answer ]]; then
	writeMessage "ABORT"
	exit -1
fi

# copy source to target 

pushd $SRC 1>/dev/null 2>&1
writeMessage "COPY" $DATA_PARTITION $targetPartition
tar cf - --checkpoint=1000 * --exclude /mnt/* | ( cd $TGT; tar xfp -)
popd 1>/dev/null 2>&1

# update fstab entry on target

writeMessage "FSTAB"
sed -i "s|\(.*\)\(\s/\s\)|$targetPartition\2|" $TGT/etc/fstab

umount $SRC 1>/dev/null 2>&1
umount $TGT 1>/dev/null 2>&1

# create backup and update commandline on boot SD to use target partition from now on

mkdir -p $SRC 
mount $BOOT_PARTITION $SRC 
if [[ ! -f $SRC/$CMD_FILE.sd ]]; then
        writeMessage "BUCMD" $CMD_FILE $BOOT_PARTITION
	cp -a $SRC/$CMD_FILE $SRC/$CMD_FILE.sd
	chmod -w $SRC/$CMD_FILE.sd	
else
        writeMessage "BUFND" $CMD_FILE.sd 
fi

writeMessage "UPDCMD" $CMD_FILE $targetPartition
sed -i "s|root=[^ ]\+|root=$targetPartition|g" $SRC/$CMD_FILE

listCurrentConfig

cleanup

# vim: tabstop=4:softtabstop=4:shiftwidth=4:noexpandtab:syntax=sh
