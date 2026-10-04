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
log "Creating new partition 3 starting at sector $exfatstartSector (type 07)..."
# 类型必须发 7 (HPFS/NTFS/exFAT)；发 11 会被 fdisk 解释成 Hidden FAT12
printf "n\np\n3\n$exfatstartSector\n\nt\n3\n7\nw\n" | sudo fdisk /dev/mmcblk0 2>&1 | tee -a "$LOG_FILE"

# ==================== Step 4: 格式化 exFAT ====================
log "=== Step 4: Format exFAT partition ==="
log "Creating exFAT filesystem on /dev/mmcblk0p3..."
sudo mkfs.exfat -c 16384 -n EASYROMS /dev/mmcblk0p3 2>&1 | tee -a "$LOG_FILE"
mkfs_rc=${PIPESTATUS[0]}
if [ "$mkfs_rc" -ne 0 ]; then
  log "mkfs.exfat -c 16384 failed, retrying with default cluster size..."
  sudo mkfs.exfat -n EASYROMS /dev/mmcblk0p3 2>&1 | tee -a "$LOG_FILE"
  mkfs_rc=${PIPESTATUS[0]}
fi
if [ "$mkfs_rc" -ne 0 ]; then
  log "ERROR: mkfs.exfat failed twice (rc=$mkfs_rc)"
  # 直接走 Step 8 失败分支，避免继续 mount 失败
  exitcode=1
else
  sync
  sleep 2
  log "Running fsck on exFAT partition..."
  sudo fsck.exfat -a /dev/mmcblk0p3 2>&1 | tee -a "$LOG_FILE"
  sync
fi

# ==================== Step 5: 挂载 roms ====================
log "=== Step 5: Mount /roms ==="
if [ "${exitcode:-0}" -eq 0 ]; then
  sudo mount -t exfat -w /dev/mmcblk0p3 /roms 2>&1 | tee -a "$LOG_FILE"
  exitcode=${PIPESTATUS[0]}
  if ! awk '$2 == "/roms" {found=1} END {exit !found}' /proc/mounts; then
    exitcode=1
  fi
  log "Mount exit code: $exitcode"
else
  log "Skip mount: mkfs failed"
fi
sleep 2

# ==================== Step 6: 解压 roms.tar ====================
log "=== Step 6: Extract roms.tar ==="
if [ "$exitcode" -eq 0 ] && [ -f /roms.tar ]; then
  log "Extracting /roms.tar to /roms (strip top-level roms/, dereference hardlinks) ..."
  sudo tar --warning=no-timestamp \
           --no-same-permissions --no-same-owner \
           --hard-dereference \
           --strip-components=1 \
           -xvf /roms.tar -C /roms 2>&1 | tee -a "$LOG_FILE"
  rc=${PIPESTATUS[0]}
  if [ "$rc" -eq 0 ]; then
    log "roms.tar extraction completed"
  else
    log "WARNING: roms.tar extraction FAILED (tar exit $rc)"
  fi
else
  if [ -f /roms.tar ]; then
    log "ERROR: /roms not mounted - skip roms.tar extraction to protect rootfs"
  else
    log "WARNING: /roms.tar not found!"
  fi
fi
sync
sleep 2

# ==================== Step 8: 挂载失败处理 (必须放在一切删除性操作之前) ====================
if [ "$exitcode" -ne 0 ]; then
  fails="$(cat /boot/.exfat_fails 2>/dev/null || echo 0)"
  fails=$((fails + 1))
  echo "$fails" | sudo tee /boot/.exfat_fails > /dev/null
  log "ERROR: Mount failed with exit code $exitcode (attempt $fails/3)"
  log "Keep /roms.tar, doneit and scripts; no fstab change - reboot and retry"
  if [ "$fails" -lt 3 ]; then
    dialog --infobox "EASYROMS conversion failed (attempt $fails of 3). The device will reboot and retry automatically." $height $width 2>&1 > /dev/tty1 | sleep 8
    sync
    reboot
  fi
  dialog --infobox "EASYROMS partition expansion and conversion to exfat failed repeatedly. Please check or replace the SD card, or expand the partition using an alternative tool such as Minitool Partition Wizard.  System will reboot and load ArkOS now." $height $width 2>&1 > /dev/tty1 | sleep 10
  sudo rm -f /boot/.exfat_fails
  log "Running /boot/clone.sh anyway (final attempt failed)..."
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

# ==================== Step 9: 配置 fstab ====================
log "=== Step 9: Configure fstab ==="
if [ -f /boot/fstab.exfat ]; then
  sudo cp /boot/fstab.exfat /etc/fstab
  log "Copied /boot/fstab.exfat to /etc/fstab"
else
  log "WARNING: /boot/fstab.exfat not found"
fi
sync

sudo rm -f /boot/doneit*
sudo rm -f /boot/.exfat_fails
log "Removed /boot/doneit marker"

# 删除 roms.tar (仅解包成功时; 失败保留供诊断与手动重试, 免去重新刷写)
if [ "$exitcode" -eq 0 ] && [ "$rc" -eq 0 ]; then
  sudo rm -f /roms.tar
  log "Removed /roms.tar"
else
  log "Keeping /roms.tar (extraction failed) - manual retry:"
  log "  sudo tar --strip-components=1 -xf /roms.tar -C /roms"
fi

sudo rm -f /boot/fstab.exfat
log "Removed /boot/fstab.exfat"

# ==================== Step 10: 调用 clone.sh ====================
log "=== Step 10: Run clone.sh ==="
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
