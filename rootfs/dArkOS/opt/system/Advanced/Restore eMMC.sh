#!/bin/bash
# Write the backup made by "Install to eMMC" back to the internal eMMC.

[ "$(id -u)" = 0 ] || exec sudo "$0" "$@"
. /usr/local/bin/buttonmon.sh
export PATH=/usr/sbin:/sbin:$PATH

EMMC=/dev/mmcblk2
BAK=/roms/backup/emmc-backup.img

msg() { printf "\n%s" "$*"; }
quit() { msg "$*"; sleep 5; exit 1; }

[ "$(findmnt -no SOURCE /)" = /dev/mmcblk0p2 ] || quit "Run this from the system on the SD card."
[ -b $EMMC ] || quit "No eMMC found. Run Install to eMMC first to enable it."
[ -f $BAK ] || quit "No backup found at $BAK."
[ $(stat -c %s $BAK) = $(blockdev --getsize64 $EMMC) ] || quit "The backup does not match the size of this eMMC."

msg "Restore the eMMC from $BAK? Everything on the eMMC will be replaced."
printf "\nPress A to continue.  Press B to exit.\n"
while true; do
  Test_Button_A; [ "$?" -eq 10 ] && break
  Test_Button_B; [ "$?" -eq 10 ] && exit 0
done

msg "Restoring the eMMC..."
umount ${EMMC}p* 2>/dev/null
dd if=$BAK of=$EMMC bs=4M conv=fsync status=progress || quit "Restoring the eMMC failed."
msg "Done. Power off and remove the SD card to start from the eMMC."
sleep 5
