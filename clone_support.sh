#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNT_DIR="${ARKOS_MNT:-/home/lcdyk/arkos/mnt}"
WORK_DIR="${ARKOS_WORK_DIR:-/home/lcdyk/arkos}"
ARKOS_IMAGE_NAME="${ARKOS_IMAGE_NAME:-}"
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
if [[ "$ARKOS_IMAGE_NAME" == *dArkOS* ]]; then
  echo "检测到 dArkOS 镜像，使用 logo-darkos"
  sudo rm -rf "$MOUNT_DIR/boot/consoles/logo"
  sudo mv "$MOUNT_DIR/boot/consoles/logo-darkos" "$MOUNT_DIR/boot/consoles/logo"
else
  echo "检测到 ArkOS 镜像，删除 logo-darkos"
  sudo rm -rf "$MOUNT_DIR/boot/consoles/logo-darkos"
fi

# 这些都是普通文件，直接复制即可
sudo cp -f ./sh/clone.sh ./dtb_selector_macos ./dtb_selector_win32.exe ./sh/expandtoexfat.sh "$MOUNT_DIR/boot/"

# 如果镜像名包含 dArkOS，使用专用的 expandtoexfat.sh
if [[ "$ARKOS_IMAGE_NAME" == *dArkOS* ]]; then
  echo "检测到 dArkOS 镜像，使用 darkos-expandtoexfat.sh"
  sudo cp -f "$SCRIPT_DIR/sh/darkos-expandtoexfat.sh" "$MOUNT_DIR/boot/expandtoexfat.sh"
fi

echo "== 注入按键信息 =="
sudo mkdir -p "$MOUNT_DIR/root/home/ark/.quirks"
# 这里你要的是把 consoles/files 这个“目录”复制进去，所以必须 -r
sudo cp -r ./consoles/files/* "$MOUNT_DIR/root/home/ark/.quirks/"
# 只有 ext4/f2fs 才能 chown，boot(FAT32) 不要 chown
sudo chown -R 1002:1002 "$MOUNT_DIR/root/home/ark/.quirks/"

echo "== 注入 clone 用配置 =="
sudo mkdir -p "$MOUNT_DIR/root/usr/bin"
sudo cp -f ./bin/mcu_led ./bin/ws2812 "$MOUNT_DIR/root/usr/bin/"
sudo cp -f ./bin/sdljoymap  ./bin/sdljoytest "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -f ./bin/console_detect "$MOUNT_DIR/root/usr/local/bin/"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/bin/ws2812" || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/bin/mcu_led" || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/sdljoytest" || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/sdljoymap" || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/console_detect" || true
sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/mcu_led" "$MOUNT_DIR/root/usr/bin/ws2812" "$MOUNT_DIR/root/usr/local/bin/sdljoytest" "$MOUNT_DIR/root/usr/local/bin/sdljoymap" "$MOUNT_DIR/root/usr/local/bin/console_detect"

echo "== 替换 modules (root) =="
SRC="./replace_file/modules"
DST="$MOUNT_DIR/root/usr/lib/modules"
if [[ -d "$SRC" ]]; then
  sudo mkdir -p "$DST"
  sudo rsync -a --delete "$SRC/" "$DST/"
  sudo chown -R 1002:1002 "$DST"
  sudo chmod -R 777 "$DST"
else
  echo "[warn] $SRC not found, skip modules update"
fi
sudo depmod -a -b "$MOUNT_DIR/root" 4.4.189 2>/dev/null || true

echo "== 注入 915 固件 =="
# 通配符不存在会让 cp 失败，加 || true 容错
sudo cp -f ./bin/rk915_*.bin "$MOUNT_DIR/root/usr/lib/firmware/" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin 2>/dev/null || true
sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin 2>/dev/null || true

echo "== 注入 aic8800DC 固件 =="
sudo mkdir -p "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC"
sudo cp -f ./bin/aic8800DC/* "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC/" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC" 2>/dev/null || true
sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC" 2>/dev/null || true

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
sudo chmod -R 777 "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null || true

echo "== 注入启动脚本 =="
sudo cp -f ./replace_file/*.sh "$MOUNT_DIR/root/usr/local/bin/"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/naomi.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/saturn.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/n64.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/pico8.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/drastic.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/drastic_kk.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/choose_drastic_ver.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/mediaplayer.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/naomi.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/saturn.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/n64.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pico8.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/drastic.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/drastic_kk.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/choose_drastic_ver.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/mediaplayer.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh" 2>/dev/null || true

echo "== 注入 adc-key 服务脚本 =="
sudo cp -f ./bin/adc-key/adckeys.py "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -f ./bin/adc-key/adckeys.sh "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -f ./bin/adc-key/adckeys.service "$MOUNT_DIR/root/etc/systemd/system/"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/adckeys.py" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/adckeys.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/etc/systemd/system/adckeys.service" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/adckeys.py" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/adckeys.sh" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/adckeys.service" 2>/dev/null || true


echo "== 注入核心 =="
sudo cp -f ./mod_so/64/* "$MOUNT_DIR/root/home/ark/.config/retroarch/cores/"
sudo cp -f ./mod_so/32/* "$MOUNT_DIR/root/home/ark/.config/retroarch32/cores/"
sudo chown -R 1002:1002 $MOUNT_DIR/root/home/ark/.config/retroarch/cores/*
sudo chown -R 1002:1002 $MOUNT_DIR/root/home/ark/.config/retroarch32/cores/*
sudo chmod -R 777 $MOUNT_DIR/root/home/ark/.config/retroarch/cores/*
sudo chmod -R 777 $MOUNT_DIR/root/home/ark/.config/retroarch32/cores/*
sudo cp -f ./replace_file/es_systems.cfg "$MOUNT_DIR/root/etc/emulationstation/"
sudo cp -f ./replace_file/es_systems.cfg.dual "$MOUNT_DIR/root/etc/emulationstation/"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual" 2>/dev/null || true
sudo cp -rf ./replace_file/resources/* "$MOUNT_DIR/root/usr/bin/emulationstation/resources/"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/bin/emulationstation/resources"
sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/emulationstation/resources"
sudo rm -rf "$MOUNT_DIR/root/etc/emulationstation/es_input.cfg" 2>/dev/null || true
sudo cp -r ./replace_file/emulationstation "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"
sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"

echo "== 还原drastic =="
sudo rm -rf "$MOUNT_DIR/root/opt/drastic" 2>/dev/null || true
sudo mkdir -p "$MOUNT_DIR/root/opt/drastic" 2>/dev/null || true
sudo cp -a ./replace_file/drastic/. "$MOUNT_DIR/root/opt/drastic/" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/drastic" 2>/dev/null || true
sudo chmod -R 777 "$MOUNT_DIR/root/opt/drastic" 2>/dev/null || true

echo "== 添加drastic-kk =="
sudo mkdir -p "$MOUNT_DIR/root/opt/drastic-kk" 2>/dev/null || true
sudo cp -a ./replace_file/drastic-kk/. "$MOUNT_DIR/root/opt/drastic-kk/" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/drastic-kk/patch" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/drastic-kk" 2>/dev/null || true
sudo chmod -R 777 "$MOUNT_DIR/root/opt/drastic-kk" 2>/dev/null || true
sudo cp -f ./bin/json-c3/* "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/" || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/libjson-c.so*" 2>/dev/null || true
sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/libjson-c.so*" 2>/dev/null || true

echo "== 更新 PPSSPP 1.20.2 =="
sudo cp -a ./replace_file/ppsspp/* "$MOUNT_DIR/root/opt/ppsspp/" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/ppsspp/" 2>/dev/null || true
sudo chmod -R 777 "$MOUNT_DIR/root/opt/ppsspp/" 2>/dev/null || true

echo "== 更新 ScummVM v2026.1.0 =="
sudo cp -a ./replace_file/scummvm/* "$MOUNT_DIR/root/opt/scummvm/" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/scummvm/" 2>/dev/null || true
sudo chmod -R 777 "$MOUNT_DIR/root/opt/scummvm/" 2>/dev/null || true

if [ "$(stat -c%s $MOUNT_DIR/root/roms.tar 2>/dev/null || echo 0)" -le $((100*1024*1024)) ]; then
  echo "== 复制 roms.tar 出来操作 =="
  sudo cp "$MOUNT_DIR/root/roms.tar" "$WORK_DIR/"
  mkdir -p "$WORK_DIR/tmproms"
  tar -xf "$WORK_DIR/roms.tar" -C "$WORK_DIR/tmproms"
  mkdir -p "$WORK_DIR/tmproms/roms/hbmame"
  tar -xf "$SCRIPT_DIR/zulu11.48.21-ca-jdk11.0.11-linux_aarch64.tar.gz" -C "$WORK_DIR/tmproms/roms/j2me"
  rm -rf "$WORK_DIR/tmproms/roms/j2me/jdk"
  mv "$WORK_DIR/tmproms/roms/j2me/zulu11.48.21-ca-jdk11.0.11-linux_aarch64" "$WORK_DIR/tmproms/roms/j2me/jdk"
  sudo chown -R root:root "$WORK_DIR/tmproms/roms/j2me/jdk"
  sudo chmod -R 777 "$WORK_DIR/tmproms/roms/j2me/jdk"
  echo "== 注入 portmaster =="
  mkdir -p "$WORK_DIR/tmproms/roms/tools/PortMaster/"
  sudo cp -rf ./PortMaster/* "$WORK_DIR/tmproms/roms/tools/PortMaster/"
  sudo cp -rf ./bin/pm_libs/* "$WORK_DIR/tmproms/roms/tools/PortMaster/libs"
  sudo cp -rf ./PortMaster/PortMaster.sh "$WORK_DIR/tmproms/roms/tools/PortMaster.sh"
  sudo chown -R 1002:1002 "$WORK_DIR/tmproms/roms/tools/PortMaster"
  sudo chown -R 1002:1002 "$WORK_DIR/tmproms/roms/tools/PortMaster.sh"
  sudo chmod -R 777 "$WORK_DIR/tmproms/roms/tools/PortMaster"
  sudo chmod -R 777 "$WORK_DIR/tmproms/roms/tools/PortMaster.sh"
  mkdir -p "$WORK_DIR/tmproms/roms/pymo"
  if [[ "$ARKOS_IMAGE_NAME" == *dArkOS* ]]; then
    echo "== 注入 dArkOS 主题 =="
    sudo cp -r ./replace_file/pymo/pymo "$WORK_DIR/tmproms/roms/themes/es-theme-nes-box/"
    sudo chown -R root:root "$WORK_DIR/tmproms/roms/themes/es-theme-nes-box/pymo"
    sudo chmod -R 777 "$WORK_DIR/tmproms/roms/themes/es-theme-nes-box/pymo"
  else
    echo "== 注入 ArkOS 主题 =="
    sudo cp -r ./replace_file/pymo/pymo "$MOUNT_DIR/root/tempthemes/es-theme-nes-box/"
    sudo chown -R root:root "$MOUNT_DIR/root/tempthemes/es-theme-nes-box/pymo"
    sudo chmod -R 777 "$MOUNT_DIR/root/tempthemes/es-theme-nes-box/pymo" 
  fi
  sudo cp -rf  ./replace_file/pymo/Scan_for_new_games.pymo "$WORK_DIR/tmproms/roms/pymo/"
  sudo chown -R 1002:1002 "$WORK_DIR/tmproms/roms/pymo/Scan_for_new_games.pymo"
  sudo chmod -R 777 "$WORK_DIR/tmproms/roms/pymo/Scan_for_new_games.pymo"
  sudo tar -cf "$WORK_DIR/roms.tar" -C "$WORK_DIR/tmproms" .
  sudo rm -rf "$WORK_DIR/tmproms"
  sudo cp "$WORK_DIR/roms.tar" "$MOUNT_DIR/root/"
  sudo chmod -R 777 $MOUNT_DIR/root/roms.tar
  sudo rm -rf "$WORK_DIR/roms.tar"
else
  echo "== 跳过 roms.tar 操作 ="
fi

echo "== 调整retrorun =="
sudo cp -r ./replace_file/retrorun/retrorun32 "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -r ./replace_file/retrorun/retrorun "$MOUNT_DIR/root/usr/local/bin/"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/retrorun32"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/retrorun"
sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorun32"
sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorun"

echo "== 注入pymo =="
sudo cp -r ./replace_file/pymo/cpymo "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -r ./replace_file/pymo/pymo.sh "$MOUNT_DIR/root/usr/local/bin/"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/cpymo"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/pymo.sh"
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/cpymo"
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pymo.sh"

echo "== ogage快捷键复制 =="
sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/usr/local/bin/"
sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/home/ark/.quirks/"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/ogage"
sudo chown -R 1002:1002 "$MOUNT_DIR/root/home/ark/.quirks/ogage"
sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/ogage"
sudo chmod -R 777 "$MOUNT_DIR/root/home/ark/.quirks/ogage"

echo "== service的调整 =="
sudo cp -r ./replace_file/services/351mp.service "$MOUNT_DIR/root/etc/systemd/system/" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/etc/systemd/system/351mp.service" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/lib/systemd/system/mpv.service" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/351mp.service" 2>/dev/null || true
sudo chmod 777 "$MOUNT_DIR/root/lib/systemd/system/mpv.service" 2>/dev/null || true
sudo rm "$MOUNT_DIR/root/etc/systemd/system/batt_led.service" 2>/dev/null || true
sudo rm "$MOUNT_DIR/root/etc/systemd/system/ddtbcheck.service" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/opt/system/Advanced/" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$MOUNT_DIR/root/opt/system/Advanced/" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Disable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Switch to main SD for Roms.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null || true
sudo cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/system/Advanced/"*.sh 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/Enable Quick Mode.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/Disable Quick Mode.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/Switch to main SD for Roms.sh" 2>/dev/null || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/usr/local/bin/Switch to SD2 for Roms.sh" 2>/dev/null || true
sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/"*.sh 2>/dev/null || true

echo "== 删除logo随机 =="
sudo sed -i '/imageshift\.sh/d' "$MOUNT_DIR/root/var/spool/cron/crontabs/root" 2>/dev/null || true
sudo rm "$MOUNT_DIR/root/home/ark/.config/imageshift.sh" 2>/dev/null || true

echo "== 临时更新 =="
sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/mediaplayer.sh"

echo "== 删除不需要的文件 =="
sudo rm -rf "$MOUNT_DIR/boot/BMPs" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/boot/ScreenFiles" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/boot/boot.ini" $MOUNT_DIR/boot/*.dtb $MOUNT_DIR/boot/*.orig $MOUNT_DIR/boot/*.tony $MOUNT_DIR/boot/Image $MOUNT_DIR/boot/*.bmp $MOUNT_DIR/boot/WHERE_ARE_MY_ROMS.txt 2>/dev/null || true
# 根据镜像名设置不同的标题
if [[ "$ARKOS_IMAGE_NAME" == *dArkOS* ]]; then
  sudo sed -i "/title\=/c\title\=dArkOS4Clone ($UPDATE_DATE)($MODDER)" "$MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth"
else
  sudo sed -i "/title\=/c\title\=ArkOS4Clone ($UPDATE_DATE)($MODDER)" "$MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth"
fi
sudo rm -rf "$MOUNT_DIR/boot/DTB Change Tool.exe" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/DeviceType" 2>/dev/null || true
# sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Video Boot/"
# sudo rm -rf "$MOUNT_DIR/root/opt/system/Set Launchimage to ascii or pic.sh"
# sudo rm -rf "$MOUNT_DIR/root/opt/system/Wifi-Toggle.sh"
# sudo rm -rf "$MOUNT_DIR/root/opt/system/Set Launchimage to vid.sh"
sudo rm -rf "$MOUNT_DIR/root/opt/system/Change LED to Red.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Update.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Wifi.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Network Info.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Enable Remote Services.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Disable Remote Services.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Change Time.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/NDS Overlays" 2>/dev/null || true

sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Change Ports SDL.sh" 2>/dev/null || true
find "$MOUNT_DIR/root/opt/system/Advanced" -name 'Restore*.sh' ! -name 'Restore ArkOS Settings.sh' -exec rm -f {} + 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Screen - Switch to Original Screen Timings.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Reset EmulationStation Controls.sh" 2>/dev/null || true
sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Fix Global Hotkeys.sh" 2>/dev/null || true

if [[ "$ARKOS_IMAGE_NAME" == *dArkOS* ]]; then
  sudo mkdir "$MOUNT_DIR/root/opt/system/Tools/" || true
  sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Backup dArkOS Settings" 2>/dev/null || true
  sudo rm -rf "$MOUNT_DIR/root/opt/system/Tools/Install.PortMaster.sh" 2>/dev/null || true
fi
sudo cp -r "./Jason3_Scripte/wifi-toggle/Wifi-toggle.sh" "$MOUNT_DIR/root/opt/system/Wifi-Toggle.sh" || true
sudo cp -r "./Jason3_Scripte/InfoSystem/InfoSystem.sh" "$MOUNT_DIR/root/opt/system/Tools/System Info.sh" || true
sudo cp -r "./Jason3_Scripte/GhostLoader/GhostLoader.sh" "$MOUNT_DIR/root/opt/system/Tools/Ghost Loader.sh" || true
sudo cp -r "./Jason3_Scripte/Bluetooth-Manager/Bluetooth Manager.sh" "$MOUNT_DIR/root/opt/system/Tools/" || true
sudo cp -r "./Jason3_Scripte/Bluetooth-Manager/patch.pak" "$MOUNT_DIR/root/opt/system/Tools/" || true

sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/system/"*.sh || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/system/Tools/"*.sh || true
sudo chown -R 1002:1002 "$MOUNT_DIR/root/opt/system/Advanced/"*.sh || true
sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/"*.sh || true
sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/Tools/"*.sh || true
sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/Advanced/"*.sh || true

sudo touch $MOUNT_DIR/boot/"USE_DTB_SELECT_TO_SELECT_DEVICE" 2>/dev/null || true
cat $MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth || true
echo "== 完成 =="
