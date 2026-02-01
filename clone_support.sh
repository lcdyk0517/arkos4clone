#!/usr/bin/env bash
set -euo pipefail

MOUNT_DIR="/home/lcdyk/arkos/mnt"
UPDATE_DATE="$(TZ=Asia/Shanghai date +%m%d%Y)"
MODDER="kk&lcdyk"

# 统一的 rsync 选项：
# -rltD   ：递归/保留软链/保留时间/保留设备文件（尽量通用）
# --no-owner --no-group --no-perms ：不要在 FAT32 上设置属主/属组/权限，避免 EPERM
# --omit-dir-times ：不尝试写目录时间戳（FAT32 上也可能受限）
RSYNC_BOOT_OPTS="-rltD --no-owner --no-group --no-perms --omit-dir-times"

echo "== 注入 boot =="
sudo mkdir -p "$MOUNT_DIR/boot/consoles"
# 不同步 consoles/files 目录（按你原本需求）
sudo rsync $RSYNC_BOOT_OPTS --exclude='files' ./consoles/ "$MOUNT_DIR/boot/consoles/"

# 这些都是普通文件，直接复制即可
sudo cp -f ./sh/clone.sh ./dtb_selector_macos ./dtb_selector_win32.exe ./sh/expandtoexfat.sh "$MOUNT_DIR/boot/"

echo "== 注入按键信息 =="
sudo mkdir -p "$MOUNT_DIR/root/home/ark/.quirks"
# 这里你要的是把 consoles/files 这个“目录”复制进去，所以必须 -r
sudo cp -r ./consoles/files/* "$MOUNT_DIR/root/home/ark/.quirks/"
# 只有 ext4/f2fs 才能 chown，boot(FAT32) 不要 chown
sudo chown -R 1002:1002 "$MOUNT_DIR/root/home/ark/.quirks/"

echo "== 注入 clone 用配置 =="
sudo mkdir -p "$MOUNT_DIR/root/opt/system/Clone" "$MOUNT_DIR/root/usr/bin"
sudo cp -f ./sh/joyled.sh "$MOUNT_DIR/root/opt/system/Clone/"
sudo cp -f ./sh/sdljoytest.sh "$MOUNT_DIR/root/opt/system/Clone/"
sudo cp -f ./bin/mcu_led ./bin/ws2812 "$MOUNT_DIR/root/usr/bin/"
sudo cp -f ./bin/sdljoymap  ./bin/sdljoytest "$MOUNT_DIR/root/usr/local/bin/"
sudo chown -f 1002:1002 "$MOUNT_DIR/root/usr/bin/ws2812" || true
sudo chown -f 1002:1002 "$MOUNT_DIR/root/usr/bin/mcu_led" || true
sudo chown -f 1002:1002 "$MOUNT_DIR/root/usr/local/bin/sdljoytest" || true
sudo chown -f 1002:1002 "$MOUNT_DIR/root/usr/local/bin/sdljoymap" || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/system/Clone"
sudo chmod -R 755 "$MOUNT_DIR/root/opt/system/Clone"
sudo chmod 755 "$MOUNT_DIR/root/usr/bin/mcu_led" "$MOUNT_DIR/root/usr/bin/ws2812" "$MOUNT_DIR/root/usr/local/bin/sdljoytest" "$MOUNT_DIR/root/usr/local/bin/sdljoymap"

echo "== 替换 modules (root) =="
SRC="./replace_file/modules"
DST="$MOUNT_DIR/root/usr/lib/modules"
if [[ -d "$SRC" ]]; then
  sudo mkdir -p "$DST"
  sudo rsync -a --delete "$SRC/" "$DST/"
else
  echo "[warn] $SRC not found, skip modules update"
fi
sudo depmod -a -b "$MOUNT_DIR/root" 4.4.189 2>/dev/null || true

echo "== 注入 915 驱动 =="
sudo mkdir -p "$MOUNT_DIR/root/usr/lib/firmware" \
             "$MOUNT_DIR/root/usr/lib/modules/4.4.189/kernel/drivers/net/wireless"
# 通配符不存在会让 cp 失败，加 || true 容错
sudo cp -f ./bin/rk915_*.bin "$MOUNT_DIR/root/usr/lib/firmware/" 2>/dev/null || true
sudo mkdir -p "$MOUNT_DIR/root/usr/lib/modules/4.4.189/kernel/drivers/net/wireless/rockchip_wlan/rk915"
sudo cp -f ./bin/rk915.ko "$MOUNT_DIR/root/usr/lib/modules/4.4.189/kernel/drivers/net/wireless/rockchip_wlan/rk915/" 2>/dev/null || true
sudo chmod 644 "$MOUNT_DIR/root/usr/lib/modules/4.4.189/kernel/drivers/net/wireless/rockchip_wlan/rk915/rk915.ko" 2>/dev/null || true
sudo chmod 755 "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin 2>/dev/null || true

echo "== 注入 351Files 资源 =="
sudo mkdir -p "$MOUNT_DIR/root/opt/351Files/res"
# 这里 res/* 是多个“目录”，必须 -r
sudo cp -r ./res/* "$MOUNT_DIR/root/opt/351Files/res/" 2>/dev/null || true

# 重命名 351Files -> 351Files.old（存在才动）
if [[ -e "$MOUNT_DIR/root/opt/351Files/351Files" ]]; then
  sudo mv "$MOUNT_DIR/root/opt/351Files/351Files" "$MOUNT_DIR/root/opt/351Files/351Files.old"
else
  echo "[warn] 未找到 $MOUNT_DIR/root/opt/351Files/351Files，跳过重命名"
fi

sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null || true
sudo chmod -R 755 "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null || true

echo "== 注入启动脚本 =="
sudo cp -f ./replace_file/*.sh "$MOUNT_DIR/root/usr/local/bin/"
sudo chown root:root "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh" 2>/dev/null || true
sudo chown root:root "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh" 2>/dev/null || true
sudo chown root:root "$MOUNT_DIR/root/usr/local/bin/naomi.sh" 2>/dev/null || true
sudo chown root:root "$MOUNT_DIR/root/usr/local/bin/saturn.sh" 2>/dev/null || true
sudo chown root:root "$MOUNT_DIR/root/usr/local/bin/n64.sh" 2>/dev/null || true
sudo chown root:root "$MOUNT_DIR/root/usr/local/bin/pico8.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/naomi.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/saturn.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/n64.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pico8.sh" 2>/dev/null || true

echo "== 注入 adc-key 服务脚本 =="
sudo cp -f ./bin/adc-key/adckeys.py "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -f ./bin/adc-key/adckeys.sh "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -f ./bin/adc-key/adckeys.service "$MOUNT_DIR/root/etc/systemd/system/"
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/adckeys.py" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/adckeys.sh" 2>/dev/null || true
sudo chmod 644 "$MOUNT_DIR/root/etc/systemd/system/adckeys.service" 2>/dev/null || true


echo "== 注入核心 =="
sudo cp -f ./mod_so/64/* "$MOUNT_DIR/root/home/ark/.config/retroarch/cores/"
sudo cp -f ./mod_so/32/* "$MOUNT_DIR/root/home/ark/.config/retroarch32/cores/"
sudo chown -R 1002:1002 $MOUNT_DIR/root/home/ark/.config/retroarch/cores/*
sudo chown -R 1002:1002 $MOUNT_DIR/root/home/ark/.config/retroarch32/cores/*
sudo cp -f ./replace_file/es_systems.cfg "$MOUNT_DIR/root/etc/emulationstation/"
sudo cp -f ./replace_file/es_systems.cfg.dual "$MOUNT_DIR/root/etc/emulationstation/"
sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual" 2>/dev/null || true
sudo cp -f ./replace_file/emulationstation2.po "$MOUNT_DIR/root/usr/bin/emulationstation/resources/locale/zh-CN/"

sudo rm -rf "$MOUNT_DIR/root/etc/emulationstation/es_input.cfg" 2>/dev/null || true

sudo cp -r ./replace_file/emulationstation "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"

echo "== 调整drastic =="
sudo rm -rf "$MOUNT_DIR/root/opt/drastic" 2>/dev/null || true
sudo mkdir -p "$MOUNT_DIR/root/opt/drastic" 2>/dev/null || true

sudo cp -a ./replace_file/drastic/. "$MOUNT_DIR/root/opt/drastic/" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/drastic/patch" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/drastic" 2>/dev/null || true
sudo chmod -R 775 "$MOUNT_DIR/root/opt/drastic" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/drastic/patch"
sudo cp -a ./replace_file/nds_sh/* "$MOUNT_DIR/root/opt/system/Advanced/NDS Overlays/" 2>/dev/null || true

if [ "$(stat -c%s $MOUNT_DIR/root/roms.tar 2>/dev/null || echo 0)" -le $((100*1024*1024)) ]; then
  echo "== 复制 roms.tar 出来操作 =="
  sudo cp "$MOUNT_DIR/root/roms.tar" /home/lcdyk/arkos/
  mkdir -p /home/lcdyk/arkos/tmproms
  tar -xf /home/lcdyk/arkos/roms.tar -C /home/lcdyk/arkos/tmproms
  mkdir -p /home/lcdyk/arkos/tmproms/roms/hbmame
  tar -xf zulu11.48.21-ca-jdk11.0.11-linux_aarch64.tar.gz -C /home/lcdyk/arkos/tmproms/roms/j2me
  mv /home/lcdyk/arkos/tmproms/roms/j2me/zulu11.48.21-ca-jdk11.0.11-linux_aarch64 /home/lcdyk/arkos/tmproms/roms/j2me/jdk
  sudo chown -R root:root /home/lcdyk/arkos/tmproms/roms/j2me/jdk
  echo "== 注入 portmaster =="
  mkdir -p /home/lcdyk/arkos/tmproms/roms/tools/PortMaster/
  sudo cp -rf ./PortMaster/* "/home/lcdyk/arkos/tmproms/roms/tools/PortMaster/"
  sudo cp -rf ./PortMaster/PortMaster.sh "/home/lcdyk/arkos/tmproms/roms/tools/PortMaster.sh"
  mkdir -p /home/lcdyk/arkos/tmproms/roms/pymo
  sudo cp -rf  ./replace_file/pymo/Scan_for_new_games.pymo "/home/lcdyk/arkos/tmproms/roms/pymo/"
  sudo tar -cf /home/lcdyk/arkos/roms.tar -C /home/lcdyk/arkos/tmproms .
  sudo rm -rf /home/lcdyk/arkos/tmproms
  sudo cp /home/lcdyk/arkos/roms.tar "$MOUNT_DIR/root/"
  sudo chmod -R 755 $MOUNT_DIR/root/roms.tar
  sudo rm -rf /home/lcdyk/arkos/roms.tar
else
  echo "== 跳过 roms.tar 操作 =="
fi

echo "== 调整retrorun =="
sudo cp -r ./replace_file/retrorun/retrorun32 "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -r ./replace_file/retrorun/retrorun "$MOUNT_DIR/root/usr/local/bin/"

echo "== 注入pymo =="
sudo cp -r ./replace_file/pymo/cpymo "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -r ./replace_file/pymo/pymo.sh "$MOUNT_DIR/root/usr/local/bin/"
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/cpymo"
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pymo.sh"
sudo cp -r ./replace_file/pymo/pymo "$MOUNT_DIR/root/tempthemes/es-theme-nes-box/"

echo "== ogage快捷键复制 =="
sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/home/ark/.quirks/"

echo "== service的调整 =="
sudo cp -r ./replace_file/services/351mp.service "$MOUNT_DIR/root/etc/systemd/system/" 2>/dev/null || true
sudo chmod 644 "$MOUNT_DIR/root/lib/systemd/system/mpv.service" 2>/dev/null || true
sudo rm "$MOUNT_DIR/root/etc/systemd/system/batt_led.service" 2>/dev/null || true
sudo rm "$MOUNT_DIR/root/etc/systemd/system/ddtbcheck.service" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/opt/system/Advanced/" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$MOUNT_DIR/root/opt/system/Advanced/" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Disable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Switch to main SD for Roms.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null || true

echo "== 删除logo随机 =="
sudo sed -i '/imageshift\.sh/d' "$MOUNT_DIR/root/var/spool/cron/crontabs/root" 2>/dev/null || true
sudo rm "$MOUNT_DIR/root/home/ark/.config/imageshift.sh" 2>/dev/null || true

echo "== 临时更新 =="
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/mediaplayer.sh"

echo "== 删除不需要的文件 =="
sudo rm -rf "$MOUNT_DIR/boot/BMPs" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/boot/ScreenFiles" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/boot/boot.ini" $MOUNT_DIR/boot/*.dtb $MOUNT_DIR/boot/*.orig $MOUNT_DIR/boot/*.tony $MOUNT_DIR/boot/Image $MOUNT_DIR/boot/*.bmp $MOUNT_DIR/boot/WHERE_ARE_MY_ROMS.txt 2>/dev/null || true
sudo sed -i "/title\=/c\title\=ArkOS4Clone ($UPDATE_DATE)($MODDER)" "$MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth"
sudo rm -rf "$MOUNT_DIR/boot/DTB Change Tool.exe" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/DeviceType" 2>/dev/null || true
# sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Video Boot/"
# sudo rm -rf "$MOUNT_DIR/root/opt/system/Set Launchimage to ascii or pic.sh"
# sudo rm -rf "$MOUNT_DIR/root/opt/system/Wifi-Toggle.sh"
# sudo rm -rf "$MOUNT_DIR/root/opt/system/Set Launchimage to vid.sh"
sudo rm -rf "$MOUNT_DIR/root/opt/system/Change LED to Red.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Change Ports SDL.sh" 2>/dev/null || true
find "$MOUNT_DIR/root/opt/system/Advanced" -name 'Restore*.sh' ! -name 'Restore ArkOS Settings.sh' -exec rm -f {} + 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Screen - Switch to Original Screen Timings.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Reset EmulationStation Controls.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Fix Global Hotkeys.sh" 2>/dev/null || true

sudo touch $MOUNT_DIR/boot/"USE_DTB_SELECT_TO_SELECT_DEVICE" 2>/dev/null || true
cat $MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth
echo "== 完成 =="
