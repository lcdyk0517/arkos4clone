#!/bin/bash

LOG_FILE="/var/log/darkos-expand.log"

# 初始化日志（追加模式）
log() {
  local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $*" | tee -a "$LOG_FILE"
}

if mountpoint -q /roms; then
  sudo umount /roms
fi
sudo chmod 666 /dev/tty1
export TERM=linux
height="15"
width="55"
if [ -f "/boot/rk3326-a10mini-linux.dtb" ] || [ -f "/boot/rk3326-rg351v-linux.dtb" ] || [ -f "/boot/rk3326-rg351mp-linux.dtb" ] || [ -f "/boot/rk3326-g350-linux.dtb" ] || [ -f "/boot/rk3326-gameforce-linux.dtb" ] || [ -f "/boot/rk3326-odroidgo3-linux.dtb" ]; then
  sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  height="20"
  width="60"
fi

if [ ! -f /boot/doneit ]; then
  sudo echo ", +" | sudo sfdisk -N 3 --force /dev/mmcblk0 &> /dev/null
  sudo touch "/boot/doneit"
  dialog --infobox "EASYROMS partition expansion and conversion to exfat in process.  The device will now reboot to continue the process..." $height $width 2>&1 > /dev/tty1
  sleep 5
  sudo reboot
fi
(
	maxSize=$(lsblk -b --output SIZE -n -d /dev/mmcblk0)

	newExtSizePct=$(printf %.2f "$((10**4 * 11000000000/$maxSize))e-4")
	newExtSizePct=$(perl -e "print 1 - $newExtSizePct")
	ExfatPctToRemain=$(perl -e "print 100 * $newExtSizePct")

	partition_type=$(df -T | grep mmcblk[0-1]p2 | cut -d ' ' -f 2)
	if [ $ExfatPctToRemain -lt "100" ]; then
	  printf "d\n3\nw\n" | sudo fdisk /dev/mmcblk0 &> /dev/null
	  sudo growpart --free-percent=$ExfatPctToRemain -v /dev/mmcblk0 2 &> /dev/null
	  if [[ "$partition_type" == *"ext"* ]]; then
		sudo resize2fs /dev/mmcblk0p2 &> /dev/null
	  elif [[ "$partition_type" == *"xfs"* ]]; then
		sudo xfs_growfs /dev/mmcblk0p2 &> /dev/null
	  elif [[ "$partition_type" == *"btrfs"* ]]; then
		sudo btrfs filesystem resize max / &> /dev/null
	  else
		echo "Don't know how to grow a $partition_type file system."
		echo ""
	  fi
	  ext4endSector=$(sudo sfdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $3}')
	  exfatstartSector=$(perl -e "print 1 + $ext4endSector")
	  echo 30
	  printf "n\np\n3\n$exfatstartSector\n\nt\n3\n11\nw\n" | sudo fdisk /dev/mmcblk0 &> /dev/null
	  echo 45
	fi

	sudo mkfs.exfat -c 16K -L EASYROMS /dev/mmcblk0p3 &> /dev/null
	sync
	echo 50
	sleep 2
	sudo fsck.exfat -a /dev/mmcblk0p3 &> /dev/null
	sync
	echo 55
	printf "t\n3\n7\nw\n" | sudo fdisk /dev/mmcblk0 &> /dev/null
	echo 60
	sudo mount -t exfat -w /dev/mmcblk0p3 /roms &> /dev/null
	exitcode=$?
	echo $exitcode > /tmp/code.txt
	sleep 2
	#sudo tar -xf /roms.tar -C / &> /dev/null
	(pv -n /roms.tar | tar --no-same-permissions --no-same-owner --warning=no-timestamp -xf - -C /) &> /tmp/tar_stat.txt &
	let COUNT=1
	while true; do
	  VAL=$(tail -n 1 /tmp/tar_stat.txt | tr -d '\000')
	  if [[ "$VAL" == "100" ]]; then
	   VAL_INT=$(awk "BEGIN {print ($VAL / 100) * 20 + 60}" 2> /dev/null | cut -d '.' -f1)
	   echo $VAL_INT
	   break
	  elif [[ "$VAL" != "$SAMEVAL" ]]; then
	   VAL_INT=$(awk "BEGIN {print ($VAL / 100) * 20 + 60}" 2> /dev/null | cut -d '.' -f1)
	   echo $VAL_INT
	   SAMEVAL="$VAL"
	   continue
	  elif [[ $COUNT -ge 15000 ]]; then
	   echo "We're failing out for creating roms structure."
	   break
	  else
	   let COUNT++
	   continue
	  fi
	done
	#echo 80
	sync
	sudo rm -rf /roms/themes/es-theme-nes-box/ &> /dev/null
	cd /tempthemes
	(tar --no-same-permissions --no-same-owner --warning=no-timestamp -cf - . | pv -n -s $(du -sb /tempthemes/ | awk '{print $1}') | tar --no-same-permissions --no-same-owner -xf - -C /roms/themes/) &> /tmp/tar_stat.txt &
	let COUNT=1
	while true; do
	  VAL=$(tail -n 1 /tmp/tar_stat.txt)
	  if [[ "$VAL" -ge "100" ]]; then
	   VAL_INT_CP=$(awk "BEGIN {print ($VAL / 100) * 15 + 80}" 2> /dev/null | cut -d '.' -f1)
	   echo $VAL_INT_CP
	   break
	  elif [[ "$VAL" != "$SAMEVAL" ]] && [[ ! -z "$VAL" ]]; then
	   VAL_INT_CP=$(awk "BEGIN {print ($VAL / 100) * 15 + 80}" 2> /dev/null | cut -d '.' -f1)
	   echo $VAL_INT_CP
	   SAMEVAL="$VAL"
	   continue
	  elif [[ $COUNT -ge 15000 ]]; then
	   echo "We're failing out for copying themes."
	   break
	  else
	   let COUNT++
	   continue
	  fi
	done
	sync
	#echo 95
	sleep 1
	cd ..
	while true; do
	  if [[ -z $(pidof tar) ]]; then
		sudo rm -rf /tempthemes &> /dev/null
		break
	  fi
	done
	sleep 2
	sudo cp -f /boot/fstab.exfat /etc/fstab &> /dev/null
	sync
	sudo rm -f /boot/doneit* &> /dev/null
	if [ ! -f "/boot/rk3326-rg351v-linux.dtb" ] && [ ! -f "/boot/rk3326-rg351mp-linux.dtb" ] && [ ! -f "/boot/rk3326-g350-linux.dtb" ]; then
	  sudo rm -f /roms.tar &> /dev/null
	fi
	sudo rm -f /boot/fstab.exfat &> /dev/null
	echo 100
) | dialog --title "Firstboot setup of dArkOS" --gauge "Expanding rootfs and exfat partitions.  Please wait..." $height $width 0 2>&1 > /dev/tty1

exitcode=$(cat /tmp/code.txt)
if [ "$exitcode" == "0" ]; then
  dialog --infobox "Completed expansion of root filesystem and EASYROMS partition and conversion to exfat. The system will now reboot and load dArkOS." $height $width 2>&1 > /dev/tty1 | sleep 10

  log "Running /boot/clone.sh..."
  /boot/clone.sh 2>&1 | tee -a "$LOG_FILE" || log "clone.sh exited with error (ignored)"
  
  # systemctl disable firstboot.service
  # sudo rm -v /boot/firstboot.sh
  
  log "Copying clone.sh to firstboot.sh..."
  sudo cp /boot/clone.sh /boot/firstboot.sh
  sudo rm /boot/clone.sh
  sudo rm -v -- "$0" 2>&1 | tee -a "$LOG_FILE"
  
  log "========== expandtoexfat.sh Complete =========="
  
  dialog --colors --infobox \
  "Clone adjustment completed. The system will now reboot.  

  \Z1\ZbNote:\Zn On the first boot, PortMaster will install some dependencies. This may take a few minutes, so please be patient." \
  $height $width 2>&1 > /dev/tty1 | sleep 10
  reboot
else
  dialog --infobox "EASYROMS partition expansion and conversion to exfat failed for an unknown reason.  Please expand the partition using an alternative tool such as Minitool Partition Wizard.  System will reboot and load dArkOS now." $height $width 2>&1 > /dev/tty1 | sleep 10
  /boot/clone.sh 2>&1 | tee -a "$LOG_FILE" || log "clone.sh exited with error (ignored)"
  
  # systemctl disable firstboot.service
  # sudo rm -v /boot/firstboot.sh
  
  sudo cp /boot/clone.sh /boot/firstboot.sh
  sudo rm /boot/clone.sh
  sudo rm -v -- "$0" 2>&1 | tee -a "$LOG_FILE"
  reboot
fi

