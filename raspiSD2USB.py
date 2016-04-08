#!/usr/bin/python
# -*- coding: utf-8 -*-
##################################################################################################### 
# 
# --- Purpose:
#
# Copy user root partition from SD card to another partition (e.g. USB stick or external USB disk)
# and update required files such that from now on the other partition will be used by raspberry
# and SD card is only needed for raspberry boot process 
#
# 1) Valid candidates for new root partition:
#    a) filesystem type has to match
#    b) target partition has to have enough space
#    c) target partition has to be empty
# 2) Backup SD card boot command file cmdline.txt to cmdline.txt.sd
# 3) Update SD card boot command file cmdline.txt to use the new partition from now on
# 5) Copy all files from SD root partition /dev/mmcblk0p2 to target partition
# 6) Update /etc/fstab file on target partition
#
# --- Notes: 
#
# 1) No data is deleted from any partition in any case
# 2) If something went wrong the saved file cmdline.txt.sd on /dev/mmcblk0p1 can be 
#    copied to cmdline.txt and the original SD root partition will be used again on next boot
# 3) If there are multiple USB disks connected the target device partition type has to be gpt instead of mbr 
#
#####################################################################################################
#
#    Copyright (C) 2015-2016 framp at linux-tips-and-tricks dot de
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

import subprocess
import re
import os
import sys
import logging.handlers
import argparse
import math
import locale
import traceback

# various constants

SSD_DEVICE_CARD = "/dev/mmcblk0"
SSD_DEVICE = SSD_DEVICE_CARD + "p"
BOOT_PARTITION = SSD_DEVICE + "1"
ROOT_PARTITION = SSD_DEVICE + "2"
CMD_FILE = "/boot/cmdline.txt"
ROOTFS = "/dev/root"
MYSELF = os.path.basename(__file__)
MYNAME = os.path.splitext(os.path.split(MYSELF)[1])[0]
LICENSE="This program comes with ABSOLUTELY NO WARRANTY; This is free software, and you are welcome to redistribute it under certain conditions"

VERSION = "0.2.3.2"    

GIT_DATE = "$Date$"
GIT_DATE_ONLY = GIT_DATE.split(' ')[1]
GIT_TIME_ONLY = GIT_DATE.split(' ')[2]
GIT_COMMIT = "$Sha1$"
GIT_COMMIT_ONLY = GIT_COMMIT.split(' ')[1][:-1]

GIT_CODEVERSION = MYSELF + " V" + str(VERSION) + " " + GIT_DATE_ONLY + "/" + GIT_TIME_ONLY + " " + GIT_COMMIT_ONLY

# return big number human readable in KB, MB ...

def asReadable(number):

	if number is None:
		return "NA"

	if not isinstance(number, float):
		number = float(number)
	
	table = [[4, " TB"], [3, " GB"], [2, " MB"], [1, " KB"] , [0, ""]]
	
	v = next(e for e in table if number > math.pow(1024, e[0]))
	return "%.2f%s" % (number / math.pow(1024, v[0]), v[1])

# execute an OS command

def executeCommand(command, noRC=True):
	global logger
	rc = None
	result = None
	try:
		logger.debug("Executing command %s " % command)
		proc = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
		result = proc.communicate()[0]
		logger.debug("Result: %s " % result)

		rc = proc.returncode		
		logger.debug("RC: %s " % rc)
		if rc != 0 and noRC:
			raise Exception("Command '%s' failed with rc %d" % (command, rc))
		
	except OSError, e:
		logger.error("%s", e)
		raise e		 
	
	if noRC:
		return result
	else:	
		return (rc, result)

# i18n
	
class MessageCatalog(object):

	# locale.setlocale(locale.LC_ALL, '')

	__locale = locale.getdefaultlocale()[0].upper().split("_")[0] 

# 	__locale = "DE"

	if not __locale in ("DE"):
		__locale = "EN"

	@staticmethod
	def getLocalizedMessage(message, *messageArguments):
		if not MessageCatalog.__locale in message:
			return message[MessageCatalog.MSG_UNDEFINED].format(message)
		else:
			return message[MessageCatalog.__locale].format(*messageArguments)

	@staticmethod
	def getDefaultLocale():
		return MessageCatalog.__locale

	@staticmethod
	def setLocale(locale):
		MessageCatalog.__locale=locale.upper()
		return MessageCatalog.__locale

	@staticmethod
	def getSupportedLocales():
		return [ 'EN', 'DE' ]

	@staticmethod
	def isSupportedLocale(locale):
		return locale.upper() in MessageCatalog.getSupportedLocales()
	
	MSG_UNDEFINED = {
                   "EN": "RSD0001E ??? Undefined message for {0}",
                   "DE": "RSD0001E ??? Unbekannte Meldung für {0}" }
	MSG_VERSION = {
                   "EN": "{0}",
                   "DE": "{0}" 
	}
	MSG_DETECTED_PARTITIONS = {
				   "EN": "RSD0002I --- Detected following partitions",
				   "DE": "RSD0002I --- Folgende Partitionen wurden erkannt"
	}
	MSG_DETECTED_PARTITION = {
				   "EN": "RSD0003I --- {0} - Size: {1} - Free: {2} - Mountpoint: {3} - Partitiontype: {4} - Partitiontable: {5}",
				   "DE": "RSD0003I --- {0} - Größe: {1} - Frei: {2} - Mountpunkt: {3} - Partitionstyp: {4} - Partitiontabelle: {5}"
	}
	MSG_NO_ELIGIBLE_ROOT = {
				   "EN": "RSD0004E ??? No eligible target root partitions found",
				   "DE": "RSD0004E ??? Keine mögliche Ziel root Partition gefunden"
	}
	MSG_ELIGIBLES_AS_ROOT = {
				   "EN": "RSD0005I --- Following partitions are eligible as new target root partition",
				   "DE": "RSD0005I --- Folgende Partitionen sind mögliche neue Ziel root Partition"
	}
	MSG_ELIGIBLE_AS_ROOT = {
				   "EN": "RSD0006I --- {0}",
				   "DE": "RSD0006I --- {0}"
	}
	MSG_ENTER_PARTITION = {
				   "EN": "RSD0007I --- Enter partition: ",
				   "DE": "RSD0007I --- Partion eingeben: "
	}
	MSG_PARTITION_INVALIDE = {
				   "EN": "RSD0008E ??? Partition {0} does not exist",
				   "DE": "RSD0008E ??? Partition {0} gibt es nicht"
	}
	MSG_TARGET_PARTITION_CANDIDATES = {
				   "EN": "RSD0009I --- Target root partition candidates: {0}",
				   "DE": "RSD0009I --- Ziel root Partitionskandidaten: {0}"
	}
	MSG_ROOT_ALREADY_MOVED = {
				   "EN": "RSD0010E ??? Root partition already moved to {0}",
				   "DE": "RSD0010E ??? Root Partition wurde schon auf {0} umgezogen"
	}
	MSG_SOURCE_ROOT_PARTITION = {
				   "EN": "RSD0011I --- Source root partition {0}: size: {1} type: {2}",
				   "DE": "RSD0011I --- Quell root Partition {0}: Größe: {1} Typ: {2}"
	}	
	MSG_TESTING_PARTITION = {
				   "EN": "RSD0012I --- Testing partition {0}: Size: {1} Free space: {2} Type: {3}",
				   "DE": "RSD0012I --- Partition {0} wird getestet: Größe: {1} Freier Speicherplatz: {2} Typ: {3}",
	}	
	MSG_PARTITION_NOT_MOUNTED = {
				   "EN": "RSD0013W !!! Skipping {0} - Partition is not mounted",
				   "DE": "RSD0013W !!! Partition {0} wird übersprungen - nicht gemounted"
	}	
	MSG_PARTITION_TOO_SMALL = {
				   "EN": "RSD0014W !!! Skipping {0} - Partition is too small with {1} free space",
				   "DE": "RSD0014W !!! Partition {0} wird übersprungen - zu klein mit {1} freiem Speicherplatz"
	}	
	MSG_PARTITION_INVALID_TYPE = {
				   "EN": "RSD0015W !!! Skipping {0} - Partition has incorrect type {1}",
				   "DE": "RSD0015W !!! Partition {0} wird übersprungen - Partitionstyp {1} stimmt nicht"
	}	
	MSG_PARTITION_INVALID_FILEPARTITION = {
				   "EN": "RSD0016W !!! Skipping {0} - Partition has Partitiontabletype {1} but has to be gpt because multiple disks are attached",
				   "DE": "RSD0016W !!! Partition {0} wird übersprungen - Partition hat Partitionstabellenbtyp {1} der aber gpt sein mauss da mehrere Platten angeschlossen sind"
	}	
	MSG_PARTITION_NOT_EMPTY = {
				   "EN": "RSD0017W !!! Skipping {0} - Partition is not empty or there are more directories than /home/pi",
				   "DE": "RSD0017W !!! Partition {0} wird übersprungen - Partition ist nicht leer oder hat nicht nur das /home/pi Verzeichnis"
	}	
	MSG_PARTITION_UNKNOWN_SKIP = {
				   "EN": "RSD0018E ??? Skipping {0} for unknown reasons",
				   "DE": "RSD0018E ??? Partition {0} wird aus unbekannten Gründen übersprungen"
	}				
	MSG_PARTITION_WILL_BE_COPIED = {
				   "EN": "RSD0019I --- Partition {0} will be copied to partition {1} and become new root partition",
				   "DE": "RSD0019I --- Partition {0} wird auf Partition {1} kopiert und wird die neue root Partition"
	}				
	MSG_ARE_YOU_SURE = {
				   "EN": "RSD0020I --- Are you sure (y/N) ? ",
				   "DE": "RSD0020I --- Bist Du sicher (j/N) ? "
	}				
	MSG_COPYING_ROOT = {
				   "EN": "RSD0021I --- Copying rootpartition ... Please be patient",
				   "DE": "RSD0021I --- Rootpartition wir kopiert ... Bitte Geduld"
	}				
	MSG_UPDATING_FSTAB = {
				   "EN": "RSD0022I --- Updating /etc/fstab on {0}",
				   "DE": "RSD0022I --- /etc/fstab wird auf {0} angepasst"
	}				
	MSG_SAVING_OLD_CMDFILE = {
				   "EN": "RSD0023I --- Saving {0} on {1} as {2}",
				   "DE": "RSD0023I --- {0} wird auf {1} als {2} gesichert"
	}				
	MSG_UPDATING_CMDFILE = {
				   "EN": "RSD0024I --- Updating {0} on {1}",
				   "DE": "RSD0024I --- {0} wird auf {1} angepasst"
	}				
	MSG_DONE = {
				   "EN": "RSD0025I --- Finished moving root partition from {0} to partition {1}",
				   "DE": "RSD0025I --- Umzug von root Partition von {0} auf Partition {1} beendet"
	}				
	MSG_FAILURE = {
				   "EN": "RSD0026E ??? Unexpected exception caught: '{0}'.\nSee log file {1} for details",
				   "DE": "RSD0026E ??? Unerwartete Ausnahme: '{0}'.\nIn Logfile {1} finden sich weitere Fehlerdetails"
	}				
	MSG_NEEDS_ROOT = {
				   "EN": "RSD0027E ??? Script has to be invoked as root or with sudo",
				   "DE": "RSD0027E ??? Das Script muss als root oder mit sudo aufgerufen werden" 
	}
	MSG_TARGET_PARTITION_ON_SSDCARD = {
				   "EN": "RSD0028I --- Skipping {0} - Partition located on SD card",
				   "DE": "RSD0028I --- Partition {0} wird übersprungen - Partition liegt auf der SD Karte"
	}
	
# baseclass for all the linux commands dealing with partitions

class BashCommand(object):
	
	__SPLIT_PARTITION_REGEX = "(/dev/[a-zA-Z]+)([0-9]+)"		

	def __init__(self, command):
		self.__command = command
		self._commandResult = None
		self.__executed = False
		
	def __collect(self):
		if not self.__executed:
			self._commandResult = executeCommand(self.__command)
			self._commandResult = self._commandResult.splitlines()
			self._postprocessResult()
			self.__executed = True			
		
	def getResult(self):
		self.__collect()
		return self._commandResult

	def _postprocessResult(self):
		pass
	
	def _splitPartition(self, partition):		
		m = re.match(self.__SPLIT_PARTITION_REGEX, partition)
		if m:
			return (m.group(1), m.group(2))
		else:
			raise Exception("Unable to split partition %s into device and partition number" % (partition))
	
'''
root@raspi4G:~# df -T
Filesystem	 Type	 1K-blocks	Used Available Use% Mounted on
rootfs		 rootfs	 3683920 2508276	968796  73% /
/dev/root	  ext4	   3683920 2508276	968796  73% /
devtmpfs	   devtmpfs	244148	   0	244148   0% /dev
tmpfs		  tmpfs		49664	 236	 49428   1% /run
tmpfs		  tmpfs		 5120	   0	  5120   0% /run/lock
tmpfs		  tmpfs		99320	   0	 99320   0% /run/shm
/dev/mmcblk0p1 vfat		 57288	9864	 47424  18% /boot
'''

class df(BashCommand):
	
	def __init__(self):
		BashCommand.__init__(self, 'df -T')
		self.fileSystem = []
		
	def _postprocessResult(self):
		self._commandResult = self._commandResult[1:]
		
	def __mapRootPartition(self, partition):
		if partition == ROOT_PARTITION:
			return ROOTFS
		else:
			return partition
			
	def getSize(self, partition):
		partition = self.__mapRootPartition(partition)
		for line in self.getResult():
			lineElements = line.split()
			if lineElements[0] == partition:
				return int(lineElements[3])*1024

	def getFree(self, partition):
		partition = self.__mapRootPartition(partition)
		for line in self.getResult():
			lineElements = line.split()
			if lineElements[0] == partition:
				return int(lineElements[4])*1024

	def getType(self, partition):
		partition = self.__mapRootPartition(partition)
		for line in self.getResult():
			lineElements = line.split()
			if lineElements[0] == partition:
				return lineElements[1]
			
'''
root@raspi4G:~# lsblk -rnb
sda 8:0 1 4127195136 0 disk 
sda1 8:1 1 4126129664 0 part 
mmcblk0 179:0 0 3963617280 0 disk 
mmcblk0p1 179:1 0 58720256 0 part /boot
mmcblk0p2 179:2 0 3900702720 0 part /
'''
class lsblk(BashCommand):
	def __init__(self):
		BashCommand.__init__(self, 'lsblk -rnb')
					
	def getSize(self, filesystem):
		for line in self.getResult():
			lineElements = line.split()
			if '/dev/' + lineElements[0] == filesystem:
				return int(lineElements[3])

	def getMountpoint(self, filesystem):
		for line in self.getResult():
			lineElements = line.split()
			if '/dev/' + lineElements[0] == filesystem:
				if len(lineElements) == 7:				
					return lineElements[6]
				else:
					return None
		return None
			
	def getPartitions(self):
		result = []
		for line in self.getResult():
			lineElements = line.split()
			if lineElements[0] != SSD_DEVICE_CARD:
				result.append(lineElements[0])
		return result
	
'''
root@raspi4G:~# fdisk -l

Disk /dev/mmcblk0: 3963 MB, 3963617280 bytes
4 heads, 16 sectors/track, 120960 cylinders, total 7741440 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x000981cb

        Device Boot      Start         End      Blocks   Id  System
/dev/mmcblk0p1            8192      122879       57344    c  W95 FAT32 (LBA)
/dev/mmcblk0p2          122880     7741439     3809280   83  Linux

Disk /dev/sda: 4127 MB, 4127195136 bytes
94 heads, 60 sectors/track, 1429 cylinders, total 8060928 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk identifier: 0x00000000

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1               1     8060927     4030463+  ee  GPT

'''		
class fdisk(BashCommand):
	def __init__(self):
		BashCommand.__init__(self, 'fdisk -l 2>/dev/null')
		
	def _postprocessResult(self):
		self._commandResult = filter(lambda line: line.startswith('/dev/'), self._commandResult)
			
	def getSize(self, filesystem):
		for line in self.getResult():
			lineElements = line.split()
			if lineElements[0] == filesystem:
				return int(lineElements[3])
			
	def getPartitions(self):
		result = []
		for line in self.getResult():
			lineElements = line.split()
			result.append(lineElements[0])
		return result

'''
root@raspi4G:~# parted -l -m /dev/sda
BYT;
/dev/sda:4127MB:scsi:512:512:msdos:USB2.0 FlashDisk;
1:1049kB:4127MB:4126MB:ext4::;

BYT;
/dev/mmcblk0:3964MB:sd/mmc:512:512:msdos:SD SR04G;
1:4194kB:62.9MB:58.7MB:fat16::lba;
2:62.9MB:3964MB:3901MB:ext4::;
'''

class parted(BashCommand):
	def __init__(self):
		BashCommand.__init__(self, 'parted -l -m')
		
	def _postprocessResult(self):
		self._commandResult = filter(lambda line: line.startswith('/dev/'), self._commandResult)
			
	def getPartitiontableType(self, partition):
		(partition, partitionNumber) = self._splitPartition(partition)
		for line in self.getResult():
			lineElements = line.split(':')
			if lineElements[0] == partition:
				return lineElements[5]
		return None

	def isGPT(self, partition):
		return self.getPartitiontableType(partition) == "gpt"

	def isMBR(self, partition):
		return not self.isGPT(self, partition)			
		
'''
root@raspi4G:~# sgdisk -i 1 /dev/sda 
GPT fdisk (gdisk) version 0.8.5

Partition table scan:
  MBR: protective
  BSD: not present
  APM: not present
  GPT: present

Found valid GPT with protective MBR; using GPT.

Command (? for help): Using 1
Partition GUID code: 0FC63DAF-8483-4772-8E79-3D69D8477DE4 (Linux filesystem)
Partition unique GUID: AC9DC34D-BAF0-44D6-A682-610CB651E0CA
First sector: 2048 (at 1024.0 KiB)
Last sector: 8060894 (at 3.8 GiB)
Partition size: 8058847 sectors (3.8 GiB)
Attribute flags: 0000000000000000
Partition name: 'Linux filesystem'
'''
	
class sgdisk(BashCommand):
	def __init__(self, partition):
		(partition, partitionNumber) = self._splitPartition(partition)
		BashCommand.__init__(self, 'sgdisk -i %s %s' % (partitionNumber, partition))
		
	def _postprocessResult(self):
		self._commandResult = filter(lambda line: line.startswith('Partition unique'), self._commandResult)
						
	def getGUID(self):
		if len(self.getResult()) > 0: 
			lineElements = self.getResult()[0].split()
			return lineElements[3]
		else:
			return None
		
	def hasGUID(self):
		return self.getGUID() is not None
		
'''
root@raspi4G:~# blkid
/dev/mmcblk0p2: UUID="b0fe2b87-858f-4502-8169-893a41302b45" TYPE="ext4" 
/dev/mmcblk0p1: SEC_TYPE="msdos" LABEL="boot" UUID="993B-8922" TYPE="vfat" 
/dev/sda1: UUID="d806d9f1-814a-4607-a20c-6fb1ecddf48f" TYPE="ext4" 
'''
class blkid(BashCommand):
	def __init__(self):
		BashCommand.__init__(self, 'blkid')                         
		
	def getType(self, filesystem):
		for line in self.getResult():
			lineElements = line.split()
			fs = lineElements[0][:-1]
			if (fs) == filesystem:
				regex = ".*TYPE=\"([^\"]*)\""		
				m = re.match(regex, line)				
				if m:
					return m.group(1)								
		return None
	
	def getDevices(self):
		devices = []   		
		for line in self.getResult():
			lineElements = line.split()
			partition = lineElements[0][:-1]
			if not partition.startswith(SSD_DEVICE_CARD):
				devices.append(self._splitPartition(partition)[0])
		
		return list(set(devices))

# Facade for all the various device/partition commands available on Linux
	
class DeviceManager():
	
	def __init__(self):
		self.__df = df()
		self.__blkid = blkid()
		self.__lsblk = lsblk()
		self.__fdisk = fdisk()
		self.__parted = parted()
		
	def getPartitions(self):
		return self.__fdisk.getPartitions()
	
	def getSize(self, partition):
		return self.__lsblk.getSize(partition)

	def getFree(self, partition):
		return self.__df.getFree(partition)
	
	def getType(self, partition):
		return self.__blkid.getType(partition)
	
	def getMountpoint(self, partition):
		return self.__lsblk.getMountpoint(partition)
	
	def getDevices(self):
		return self.__blkid.getDevices()
	
	def isGPT(self, partition):
		return self.__parted.isGPT(partition)
		
	def getGUID(self, partition):
		return sgdisk(partition).getGUID()
	
	def getPartitiontableType(self, partition):
		return self.__parted.getPartitiontableType(partition)

	'''
	root@raspi4G:~# cat /boot/cmdline.txt
	dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait
	'''
	
	def getSDPartitions(self):
		
		if not os.path.exists(CMD_FILE):
			raise Exception("Unable to find %s" % (CMD_FILE))
			
		result = executeCommand('cat ' + CMD_FILE)

		regex = ".*root=(.*) .*rootfstype=([0-9a-zA-Z]+)"		
		m = re.match(regex, result)				
		if m:
			rootPartition = m.group(1)
			rootFilesystemType = m.group(2)
		else:
			raise Exception("Unable to detect rootPartition and/or rootfstype in %s" % (CMD_FILE))
		
		return (rootPartition, rootFilesystemType)
	
	def getAllDetected(self):
		partitions = self.getPartitions()
		details = []
		for partition in partitions:	
			size = self.getSize(partition)
			free = self.getFree(partition)
			mountpoint = self.getMountpoint(partition)
			partitiontype = self.getType(partition)
			partitionTabletype = self.getPartitiontableType(partition)
			details.append([partition, size, free, mountpoint, partitiontype, partitionTabletype])
		return details

# stderr and stdout logger 

class MyLogger(object):
	def __init__(self, stream, logger, level):
		self.stream = stream
		self.logger = logger
		self.level = level

	def write(self, message):
		self.stream.write(message)
		if len(message.rstrip()) > 1:
			self.logger.log(self.level, message.rstrip())

# detect all available partitions on system

def collectEligiblePartitions():

	global logger
	
	dm = DeviceManager()				
					
	(cmdPartition, cmdType) = dm.getSDPartitions()
	logger.debug("cmdPartition %s - %s " % (cmdPartition, cmdType))

	if cmdPartition != ROOT_PARTITION:
		raise Exception ("Current root partition %s is not located on %s " % (cmdPartition, ROOT_PARTITION))

	availableTargetPartitions = []
	
	for partition in dm.getPartitions():
		if partition.startswith(SSD_DEVICE):
			print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_TARGET_PARTITION_ON_SSDCARD, partition)
		elif dm.getType(partition) != cmdType:
			print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_PARTITION_INVALID_TYPE, partition, dm.getType(partition))
		else:
			availableTargetPartitions.append(partition)

	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_TARGET_PARTITION_CANDIDATES, ' '.join(availableTargetPartitions))
	
	sourceRootPartition = ROOT_PARTITION
	sourceRootType = dm.getType(ROOT_PARTITION)
	sourceRootSize = dm.getSize(ROOT_PARTITION)
	
	if cmdPartition != sourceRootPartition:
		print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_ROOT_ALREADY_MOVED, cmdPartition)
		sys.exit(-1) 

	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_SOURCE_ROOT_PARTITION, sourceRootPartition, asReadable(sourceRootSize), sourceRootType)
		
	validTargetPartitions = []

	multipleDevices = len(dm.getDevices()) > 1  
						
	for partition in availableTargetPartitions:
		print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_TESTING_PARTITION, partition, asReadable(dm.getSize(partition)), asReadable(dm.getFree(partition)), dm.getType(partition))
		partitionMountPoint = dm.getMountpoint(partition)
		logger.debug("partitionMountPoint: %s" % (partitionMountPoint))

		if partitionMountPoint is None:
			print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_PARTITION_NOT_MOUNTED, partition)
		elif dm.getFree(partition) < sourceRootSize:
			logger.debug("free(%s): %s - sourceRootSize: %s" % (partition, dm.getFree(partition), sourceRootSize))
			print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_PARTITION_TOO_SMALL, partition, asReadable(dm.getFree(partition)))
		elif dm.getType(partition) != sourceRootType:
			logger.debug("type(%s): %s - sourceRootSize: %s" % (partition, dm.getType(partition), sourceRootSize))
			print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_PARTITION_INVALID_TYPE, partition, dm.getType(partition))
		elif multipleDevices and not dm.isGPT(partition):
			print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_PARTITION_INVALID_FILEPARTITION, partition, dm.getPartitiontableType(partition))
		elif partition != sourceRootPartition:
			diskFilesTgt = int(executeCommand('ls -A ' + partitionMountPoint + ' | wc -l'))
			lostDir = int(executeCommand('ls -A ' + partitionMountPoint + ' | grep -i lost | wc -l'))
			piHome = os.path.exists(partitionMountPoint + '/home/pi')
			logger.debug("disksFilesTgt: %s - lostDir: %s - piHome %s" % (diskFilesTgt, lostDir, piHome))
			
			if (diskFilesTgt == 1 and lostDir == 1) or (lostDir == 0 and diskFilesTgt == 0) or piHome:
				validTargetPartitions.append(partition)
			else:
				print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_PARTITION_NOT_EMPTY, partition)
		else:
			print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_PARTITION_UNKNOWN_SKIP, partition)
							
	return validTargetPartitions, sourceRootPartition 
			
##################################################################################
################################### Main #########################################
##################################################################################

LOG_FILENAME = "./%s.log" % MYNAME
LOG_LEVEL = logging.INFO 

logLevels = { "INFO": logging.INFO , "DEBUG": logging.DEBUG, "WARNING": logging.WARNING }

parser = argparse.ArgumentParser(description="Move SD root partition to external partition on Raspberry Pi")
parser.add_argument("-l", "--log", help="log file (default: " + LOG_FILENAME + ")")
parser.add_argument("-d", "--debug", help="debug level %s (default: %s)" % ('|'.join(logLevels.keys()), logLevels.keys()[logLevels.values().index(LOG_LEVEL)]))
parser.add_argument("-g", "--language", help="message language %s (default: %s)" % ('|'.join(MessageCatalog.getSupportedLocales()), MessageCatalog.getDefaultLocale()))

args = parser.parse_args()
if args.log:
	LOG_FILENAME = args.log

if args.debug:
	if args.debug in logLevels:
		LOG_LEVEL = logLevels[args.debug]
	else:
		print "??? Invalid log level %s. Using default." % (args.debug)

if args.language:
	if MessageCatalog.isSupportedLocale(args.language):
		MessageCatalog.setLocale(args.language)
	else:
		print "??? Invalid language %s. Using default." % (args.language)

# setup logging

if os.path.isfile(LOG_FILENAME):
	os.remove(LOG_FILENAME)
	
logger = logging.getLogger(__name__)
logger.setLevel(LOG_LEVEL)
handler = logging.handlers.RotatingFileHandler(LOG_FILENAME, backupCount=1)
formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)

sys.stdout = MyLogger(sys.stdout, logger, logging.INFO)
sys.stderr = MyLogger(sys.stderr, logger, logging.ERROR)

# doit now

print LICENSE

if os.geteuid() != 0: 
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_NEEDS_ROOT)
  	sys.exit(1)

try:

	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_VERSION, GIT_CODEVERSION)
	
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_DETECTED_PARTITIONS)
	partitions = DeviceManager().getAllDetected()
	for partition in partitions:
		print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_DETECTED_PARTITION, partition[0], asReadable(partition[1]), asReadable(partition[2]), partition[3], partition[4], partition[5])
		
	(validTargetPartitions, sourceRootPartition) = collectEligiblePartitions()
	
	if len(validTargetPartitions) == 0:
		print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_NO_ELIGIBLE_ROOT)
		sys.exit(-1)
	
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_ELIGIBLES_AS_ROOT)
	for partition in validTargetPartitions:
		print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_ELIGIBLE_AS_ROOT, partition)
		
	inputAvailable = False
	while not inputAvailable:	
		selection = raw_input(MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_ENTER_PARTITION))
		inputAvailable = selection in validTargetPartitions
		if not inputAvailable:
			print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_PARTITION_INVALIDE, selection)
	
	targetRootPartition = selection
	
	dm = DeviceManager()				
	
	sourceDirectory = dm.getMountpoint(sourceRootPartition)
	targetDirectory = dm.getMountpoint(targetRootPartition)
	logger.debug("sourceDirectory: %s - targetDirectory: %s" % (sourceDirectory, targetDirectory))
	
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_PARTITION_WILL_BE_COPIED, sourceRootPartition, targetRootPartition)
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_ARE_YOU_SURE)
	selection = raw_input('')
	if selection not in ['Y', 'y', 'J', 'j']:
		sys.exit(0)
	
	command = "tar cf - --one-file-system --checkpoint=1000 %s | ( cd %s; tar xfp -)" % (sourceDirectory, targetDirectory)
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_COPYING_ROOT)
	executeCommand(command)
	
	if dm.isGPT(targetRootPartition):
		targetID = "PARTUUID=" + dm.getGUID(targetRootPartition)	
	else:
		targetID = targetRootPartition
	logger.debug("targetID: %s " % (targetID))
	
	# change /etc/fstab on target
	command = "sed -i \"s|%s|%s|\" %s/etc/fstab" % (sourceRootPartition, targetID, targetDirectory)
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_UPDATING_FSTAB, targetRootPartition)
	executeCommand(command)
	
	# create backup copy of old cmdline.txt
	command = "cp -a %s %s; chmod -w %s" % (CMD_FILE, CMD_FILE+".sd", CMD_FILE+".sd")	
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_SAVING_OLD_CMDFILE, CMD_FILE, sourceRootPartition, CMD_FILE+".sd")
	executeCommand(command)
	
	# update cmdline.txt	
	command = "sed -i \"s|root=[^ ]\+|root=%s|g\" %s/%s" % (targetID, sourceDirectory, CMD_FILE)
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_UPDATING_CMDFILE, CMD_FILE, targetRootPartition)
	executeCommand(command)
	
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_DONE, sourceRootPartition, targetRootPartition)
	
except Exception as ex:
	logger.error(traceback.format_exc())
	print MessageCatalog.getLocalizedMessage(MessageCatalog.MSG_FAILURE, ex.message, LOG_FILENAME)
