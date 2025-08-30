#!/bin/bash
sudo umount /roms
#sudo ln -s /dev/mmcblk0 /dev/hda
#sudo ln -s /dev/mmcblk0p3 /dev/hda3
sudo chmod 666 /dev/tty1
export TERM=linux
height="15"
width="55"
if [ -f "/boot/rk3326-rg351v-linux.dtb" ] || [ -f "/boot/rk3326-rg351mp-linux.dtb" ] || [ -f "/boot/rk3326-gameforce-linux.dtb" ] || [ -f "/boot/rk3326-odroidgo3-linux.dtb" ] || [ -f "/boot/rk3566.dtb" ]; then
  sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  height="20"
  width="60"
fi

if [ ! -f /boot/doneit ]; then
  sudo echo ", +" | sudo sfdisk -N 3 --force /dev/mmcblk0
  sudo touch "/boot/doneit"
  dialog --infobox "EASYROMS partition expansion and conversion to exfat in process.  The device will now reboot to continue the process..." $height $width 2>&1 > /dev/tty1
  sleep 5
  sudo reboot
fi

maxSize=$(lsblk -b --output SIZE -n -d /dev/mmcblk0)

newExtSizePct=$(printf %.2f "$((10**4 * 11000000000/$maxSize))e-4")
newExtSizePct=$(echo print 1-$newExtSizePct | perl)
ExfatPctToRemain=$(echo print 100*$newExtSizePct | perl)

#echo "$ExfatPctToRemain" > /home/ark/growpercentage.log

# Expand the ext4 partition if possible to make room for future update needs
if [ $ExfatPctToRemain -lt "100" ]; then
  printf "d\n3\nw\n" | sudo fdisk /dev/mmcblk0
  sudo growpart --free-percent=$ExfatPctToRemain -v /dev/mmcblk0 2
  sudo resize2fs /dev/mmcblk0p2
  ext4endSector=$(sudo sfdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $3}')
  exfatstartSector=$(echo print 1+$ext4endSector | perl)
  printf "n\np\n3\n$exfatstartSector\n\nt\n3\n11\nw\n" | sudo fdisk /dev/mmcblk0
fi

sudo mkfs.exfat -s 16K -n EASYROMS /dev/mmcblk0p3
sync
sleep 2
sudo fsck.exfat -a /dev/mmcblk0p3
sync
printf "t\n3\n7\nw\n" | sudo fdisk /dev/mmcblk0

sudo mount -t exfat -w /dev/mmcblk0p3 /roms
exitcode=$?
sleep 2
sudo tar -xvf /roms.tar -C /
sync
sudo rm -rf -v /roms/themes/es-theme-nes-box/
# Setup swapfile
#printf "\n\n\e[32mSetting up swapfile.  Please wait...\n"
#printf "\033[0m"
#sudo dd if=/dev/zero of=/swapfile bs=1024 count=262144
#sudo mkswap /swapfile
#sudo swapon /swapfile
sudo mv -f -v /tempthemes/* /roms/themes
sync
sleep 1
sudo rm -rf -v /tempthemes
sleep 2
#sudo umount /roms
sudo cp /boot/fstab.exfat /etc/fstab
sync
sudo rm -f /boot/doneit*
if [ ! -f "/boot/rk3326-rg351v-linux.dtb" ] && [ ! -f "/boot/rk3326-rg351mp-linux.dtb" ]; then
  sudo rm -f /roms.tar
fi
sudo rm -f /boot/fstab.exfat
# Disable and delete swapfile
#sudo swapoff /swapfile
#sudo rm -f -v /swapfile
if [ $exitcode -eq 0 ]; then
  dialog --infobox "Completed expansion of EASYROMS partition and conversion to exfat. The system will now reboot and load ArkOS." $height $width 2>&1 > /dev/tty1 | sleep 10
  systemctl disable firstboot.service
  amixer set 'Playback Path' 'HP'   
  sudo alsactl store
  sudo rm -v /boot/firstboot.sh
  sudo rm -v -- "$0"
  reboot
else
  dialog --infobox "EASYROMS partition expansion and conversion to exfat failed for an unknown reason.  Please expand the partition using an alternative tool such as Minitool Partition Wizard.  System will reboot and load ArkOS now." $height $width 2>&1 > /dev/tty1 | sleep 10
  systemctl disable firstboot.service
  amixer set 'Playback Path' 'HP'   
  sudo alsactl store
  sudo rm -v /boot/firstboot.sh
  sudo rm -v -- "$0"
  reboot
fi
