#!/bin/bash
# Build the boot files of an eMMC system from /boot/consoles, as selected in emmc.conf.
# Used by "Install to eMMC" and after an OTA update. Usage: emmc-boot-files.sh [boot dir]
set -e
B=${1:-/boot}
C="$B/consoles"
. "$B/emmc.conf"

dtb=$(ls "$C/$CONSOLE"/*.dtb)
sed -e 's|mmc 1:1|mmc 0:1|' -e 's|/dev/mmcblk0p|/dev/mmcblk2p|' "$C/$CONSOLE/boot.ini" > "$B/boot.ini"
# keep the overclock chosen in dtb_selector
[ -z "$OC" ] || sed -E -i -e 's/ (max|boot)_(cpu|gpu|ddr)freq=[0-9]+//g' \
  -e "s/^(setenv bootargs \"[^\"]*)\"/\1 $OC\"/" "$B/boot.ini"
[ -z "$VOLTAGE" ] || sed -i -e '/^setenv dtb_loadaddr/a setenv dtbo_loadaddr "0x01f30000"' \
  -e '/^load .*\.dtb$/a load mmc 0:1 ${dtbo_loadaddr} consoles/dtbo/rk3326-oc-voltage.dtbo\nfdt addr ${dtb_loadaddr}\nfdt resize 8192\nfdt apply ${dtbo_loadaddr}' "$B/boot.ini"
fdtoverlay -i "$dtb" -o "$B/$(basename "$dtb")" "$C/dtbo/rk3326-emmc.dtbo"
cp "$C/kernel/$KERNEL/Image" "$B/Image"
[ -z "$LOGO" ] || cp "$C/$LOGO" "$B/logo.bmp"
