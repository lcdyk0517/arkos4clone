#!/bin/bash

# ==================== 日志配置 ====================
LOG_FILE="/boot/boot.log"

# 初始化日志（追加模式）
log() {
  local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[$ts] $*" | tee -a "$LOG_FILE"
}

log "========== expandtoexfat.sh Start =========="

# ==================== Step 1: 卸载 roms ====================
log "=== Step 1: Unmount /roms ==="
sudo umount /roms 2>/dev/null && log "Unmounted /roms" || log "/roms not mounted or unmount failed"

#sudo ln -s /dev/mmcblk0 /dev/hda
#sudo ln -s /dev/mmcblk0p3 /dev/hda3

sudo chmod 666 /dev/tty1
export TERM=linux
height="15"
width="55"

if [ -f "/boot/rk3326-rg351v-linux.dtb" ] || [ -f "/boot/rk3326-rg351mp-linux.dtb" ] || [ -f "/boot/rk3326-gameforce-linux.dtb" ] || [ -f "/boot/rk3326-odroidgo3-linux.dtb" ] || [ -f "/boot/rk3566.dtb" ]; then
  log "Detected RK3326/RK3566 device, setting larger font"
  sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  height="20"
  width="60"
fi

# ==================== Step 2: 首次分区扩展 ====================
# p2 构建时已扩到 11G，首启不再扩容 p2，仅把 p3 扩到盘尾
log "=== Step 2: Check partition expansion status ==="
if [ ! -f /boot/doneit ]; then
  log "First run: expanding partition 3"
  sudo echo ", +" | sudo sfdisk -N 3 --force /dev/mmcblk0 2>&1 | tee -a "$LOG_FILE"
  sudo touch "/boot/doneit"
  log "Created /boot/doneit marker"
  dialog --infobox "EASYROMS partition expansion and conversion to exfat in process.  The device will now reboot to continue the process..." $height $width 2>&1 > /dev/tty1
  sleep 5
  log "Rebooting for partition expansion..."
  sudo reboot
fi
log "Partition already expanded (doneit exists)"

# ==================== Step 3: 重建 p3 (原厂流程；p2 已是 11G 不再扩容) ====================
log "=== Step 3: Recreate partition 3 ==="
printf "d\n3\nw\n" | sudo fdisk /dev/mmcblk0 2>&1 | tee -a "$LOG_FILE"

ext4endSector=$(sudo sfdisk -l /dev/mmcblk0 | grep mmcblk0p2 | awk '{print $3}')
exfatstartSector=$(echo print 1+$ext4endSector | perl)
log "Creating new partition 3 starting at sector $exfatstartSector..."
printf "n\np\n3\n$exfatstartSector\n\nt\n3\n11\nw\n" | sudo fdisk /dev/mmcblk0 2>&1 | tee -a "$LOG_FILE"

# ==================== Step 4: 格式化 exFAT ====================
log "=== Step 4: Format exFAT partition ==="
log "Creating exFAT filesystem on /dev/mmcblk0p3..."
sudo mkfs.exfat -s 16K -n EASYROMS /dev/mmcblk0p3 2>&1 | tee -a "$LOG_FILE"
sync
sleep 2

log "Running fsck on exFAT partition..."
sudo fsck.exfat -a /dev/mmcblk0p3 2>&1 | tee -a "$LOG_FILE"
sync

log "Setting partition type to exFAT (07)..."
printf "t\n3\n7\nw\n" | sudo fdisk /dev/mmcblk0 2>&1 | tee -a "$LOG_FILE"

# ==================== Step 5: 挂载 roms ====================
log "=== Step 5: Mount /roms ==="
sudo mount -t exfat -w /dev/mmcblk0p3 /roms 2>&1 | tee -a "$LOG_FILE"
exitcode=$?
log "Mount exit code: $exitcode"
sleep 2

# ==================== Step 6: 解压 roms.tar ====================
log "=== Step 6: Extract roms.tar ==="
if [ -f /roms.tar ]; then
  log "Extracting /roms.tar to / ..."
  # --no-same-owner/--no-same-permissions: exFAT 不支持 chown/chmod，
  # 不加的话每个文件都会报 Operation not permitted；属主由挂载参数 (fstab uid/gid) 决定
  sudo tar --warning=no-timestamp --no-same-permissions --no-same-owner -xvf /roms.tar -C / 2>&1 | tee -a "$LOG_FILE"
  log "roms.tar extraction completed"
else
  log "WARNING: /roms.tar not found!"
fi
sync

# 删除默认主题
if [ -d /roms/themes/es-theme-nes-box ]; then
  log "Removing default theme es-theme-nes-box..."
  sudo rm -rf -v /roms/themes/es-theme-nes-box/ 2>&1 | tee -a "$LOG_FILE"
fi

# ==================== Step 7: 移动主题 ====================
log "=== Step 7: Move tempthemes ==="
if [ -d /tempthemes ]; then
  log "Moving /tempthemes/* to /roms/themes..."
  sudo mv -f -v /tempthemes/* /roms/themes 2>&1 | tee -a "$LOG_FILE"
  sync
  sleep 1
  sudo rm -rf -v /tempthemes 2>&1 | tee -a "$LOG_FILE"
  log "tempthemes moved and cleaned"
else
  log "/tempthemes not found, skip"
fi
sleep 2

# ==================== Step 8: 配置 fstab ====================
log "=== Step 8: Configure fstab ==="
if [ -f /boot/fstab.exfat ]; then
  sudo cp /boot/fstab.exfat /etc/fstab
  log "Copied /boot/fstab.exfat to /etc/fstab"
else
  log "WARNING: /boot/fstab.exfat not found"
fi
sync

sudo rm -f /boot/doneit*
log "Removed /boot/doneit marker"

# 删除 roms.tar (非特定设备)
if [ ! -f "/boot/rk3326-rg351v-linux.dtb" ] && [ ! -f "/boot/rk3326-rg351mp-linux.dtb" ]; then
  sudo rm -f /roms.tar
  log "Removed /roms.tar"
fi

sudo rm -f /boot/fstab.exfat
log "Removed /boot/fstab.exfat"

# ==================== Step 9: 调用 clone.sh ====================
log "=== Step 9: Run clone.sh ==="
if [ $exitcode -eq 0 ]; then
  dialog --infobox "The expansion of the EASYROMS partition and conversion to exFAT have been completed. The system will now enter dArkOS Clone adjustment." $height $width 2>&1 > /dev/tty1 | sleep 3
  
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
  dialog --infobox "EASYROMS partition expansion and conversion to exfat failed for an unknown reason.  Please expand the partition using an alternative tool such as Minitool Partition Wizard.  System will reboot and load ArkOS now." $height $width 2>&1 > /dev/tty1 | sleep 10
  
  log "ERROR: Mount failed with exit code $exitcode"
  log "Running /boot/clone.sh anyway..."
  /boot/clone.sh 2>&1 | tee -a "$LOG_FILE" || log "clone.sh exited with error (ignored)"
  
  # systemctl disable firstboot.service
  # sudo rm -v /boot/firstboot.sh
  
  sudo cp /boot/clone.sh /boot/firstboot.sh
  sudo rm /boot/clone.sh
  sudo rm -v -- "$0" 2>&1 | tee -a "$LOG_FILE"
  
  log "========== expandtoexfat.sh Failed (mount error) =========="
  sleep 3
  reboot
fi
