#!/bin/bash
# Copy the system running from the SD card to the internal eMMC.
#
# eMMC layout: p1 256M FAT BOOT_EMMC, p2 root (same filesystem as the SD),
# p3 1G exFAT ROMS_EMMC (tools, bios, themes; ROMs stay on SD2).
# The kernel always names the eMMC mmcblk2, so boot.ini and fstab use it.

[ "$(id -u)" = 0 ] || exec sudo "$0" "$@"
. /usr/local/bin/buttonmon.sh
export PATH=/usr/sbin:/sbin:$PATH

SD=/dev/mmcblk0
EMMC=/dev/mmcblk2
B=/boot
EB=/mnt/emmc-boot ER=/mnt/emmc-root EM=/mnt/emmc-roms
BAK=/roms/backup/emmc-backup.img
ROMS_MIB=1024

msg() { printf "\n%s" "$*"; }
quit() { msg "$*"; sleep 5; exit 1; }
ask() {
  msg "$1"
  printf "\nPress A to continue.%s  Press B to exit.\n" "${2:+  Press X to $2.}"
  while true; do
    Test_Button_A; [ "$?" -eq 10 ] && return 0
    [ -n "$2" ] && { Test_Button_X; [ "$?" -eq 10 ] && return 1; }
    Test_Button_B; [ "$?" -eq 10 ] && exit 0
  done
}
same() { for f in "$@"; do cmp -s "$1" "$f" || return 1; done; }

[ "$(findmnt -no SOURCE /)" = ${SD}p2 ] || quit "Run this from the system on the SD card."

if [ ! -b $EMMC ]; then
  grep -q rk3326-emmc.dtbo $B/boot.ini && quit "No eMMC found on this device."
  ask "The eMMC is not enabled. Enable it and reboot? Run this again afterwards."
  sed -i -e '/^setenv dtb_loadaddr/a setenv dtbo_loadaddr "0x01f30000"' \
    -e '/^load .*\.dtb$/a load mmc 1:1 ${dtbo_loadaddr} consoles/dtbo/rk3326-emmc.dtbo\nfdt addr ${dtb_loadaddr}\nfdt resize 8192\nfdt apply ${dtbo_loadaddr}' $B/boot.ini
  sync; reboot
fi

dd if=$SD bs=512 skip=16384 count=8192 status=none | grep -qaF 'fatload ${devtype} ${devnum}:1' ||
  quit "The U-Boot on this card cannot boot from eMMC. Update the system first."

# Remember the console selection so the boot files can be rebuilt after an OTA update
dtb=$(tr -d '\r' < $B/boot.ini | awk '/^load .*\.dtb$/ {print $NF; exit}')
for d in $B/consoles/*/; do same $B/$dtb "$d$dtb" 2>/dev/null && CONSOLE=$(basename "$d"); done
for k in $B/consoles/kernel/*/Image; do same $B/Image "$k" && KERNEL=$(basename "$(dirname "$k")"); done
for l in $B/consoles/logo/*/logo.bmp; do same $B/logo.bmp "$l" && LOGO=${l#$B/consoles/}; done
[ -n "$CONSOLE" ] && [ -n "$KERNEL" ] || quit "Select the console with dtb_selector first."
OC=$(grep -oE '(max|boot)_(cpu|gpu|ddr)freq=[0-9]+' $B/boot.ini | xargs)
grep -q rk3326-oc-voltage.dtbo $B/boot.ini && VOLTAGE=1

EMMC_MIB=$(( $(cat /sys/block/mmcblk2/size) / 2048 ))
ROOT_MIB=$(( EMMC_MIB - 16 - 256 - ROMS_MIB ))
USED_MIB=$(df -m --output=used / | tail -1)
FS=$(findmnt -no FSTYPE /)
[ $FS = btrfs ] && NEED_MIB=$(( USED_MIB * 3 / 4 )) || NEED_MIB=$USED_MIB
[ $ROOT_MIB -gt $NEED_MIB ] || quit "The eMMC ($EMMC_MIB MiB) is too small for this system ($USED_MIB MiB)."

ask "Copy this system to the eMMC ($EMMC_MIB MiB)? Everything on the eMMC will be erased." \
  "back up the eMMC first" || BACKUP=1
umount ${EMMC}p* 2>/dev/null

if [ -n "$BACKUP" ]; then
  rm -f $BAK.part
  [ $(( $(df -B1 --output=avail /roms | tail -1) + $(stat -c %s $BAK 2>/dev/null || echo 0) )) -gt \
    $(blockdev --getsize64 $EMMC) ] || quit "Not enough space in /roms for the backup."
  msg "Backing up the eMMC to $BAK..."
  mkdir -p ${BAK%/*}
  dd if=$EMMC of=$BAK.part bs=4M conv=fsync status=progress && mv $BAK.part $BAK ||
    { rm -f $BAK.part; quit "Backing up the eMMC failed."; }
fi

msg "Partitioning..."
sfdisk -q --wipe always $EMMC <<EOF || quit "Partitioning failed."
label: dos
start=32768, size=256MiB, type=c, bootable
start=557056, size=${ROOT_MIB}MiB, type=83
start=$(( 557056 + ROOT_MIB * 2048 )), type=7
EOF
partx -u $EMMC; udevadm settle
mkfs.vfat -F 32 -n BOOT_EMMC ${EMMC}p1 >/dev/null &&
case $FS in
  btrfs) mkfs.btrfs -q -f -L ROOTFS_EMMC -O ^free-space-tree ${EMMC}p2 ;;
  *) mkfs.$FS -q -F -L ROOTFS_EMMC ${EMMC}p2 ;;
esac &&
mkfs.exfat -L ROMS_EMMC ${EMMC}p3 >/dev/null || quit "Formatting failed."
mkdir -p $EB $ER $EM
[ $FS = btrfs ] && OPT=compress=zlib || OPT=defaults
mount ${EMMC}p1 $EB && mount -o $OPT ${EMMC}p2 $ER && mount ${EMMC}p3 $EM || quit "Mounting the eMMC failed."

msg "Copying the boot partition..."
rsync -rt $B/ $EB/ --exclude='/dtb_selector_*' --exclude='/*.log' --exclude='/*.txt' \
  --exclude=/boot.ini --exclude='/*.dtb' --exclude=/Image --exclude=/logo.bmp
printf 'CONSOLE="%s"\nKERNEL="%s"\nLOGO="%s"\nOC="%s"\nVOLTAGE="%s"\n' \
  "$CONSOLE" "$KERNEL" "$LOGO" "$OC" "$VOLTAGE" > $EB/emmc.conf
/usr/local/bin/emmc-boot-files.sh $EB || quit "Creating the boot files failed."

msg "Copying the system, this takes a while..."
rsync -aAXHx --numeric-ids / $ER/ --exclude='/tmp/*' --exclude='/var/log/journal/*' \
  --exclude='/var/cache/apt/archives/*.deb' --exclude=/roms.tar
rc=$?; [ $rc = 0 ] || [ $rc = 24 ] || quit "Copying the system failed (eMMC full?)."
sed -i -e 's|^LABEL=BOOT |/dev/mmcblk2p1 |' -e 's|^LABEL=ROOTFS |/dev/mmcblk2p2 |' \
  -e 's|^LABEL=EASYROMS |/dev/mmcblk2p3 |' $ER/etc/fstab

msg "Copying tools, bios and themes..."
rsync -rt /roms/ $EM/ --exclude='*.squashfs' \
  --include='*/' --include='/tools/***' --include='/bios/***' --include='/themes/***' \
  --include='/launchimages/***' --include='/shutdownimages/***' --include='/bgmusic/***' --exclude='*'

msg "Copying the boot loader..."
dd if=$SD of=$EMMC bs=512 skip=64 seek=64 count=32704 conv=fsync status=none
cmp -s <(dd if=$SD bs=512 skip=64 count=32704 status=none) \
  <(dd if=$EMMC bs=512 skip=64 count=32704 status=none) || quit "Writing the boot loader failed."

sync; umount $EB $ER $EM
ask "Done. Power off now? Then remove the SD card and power on."
poweroff
