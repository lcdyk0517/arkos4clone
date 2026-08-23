#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNT_DIR="${ARKOS_MNT:-/home/lcdyk/arkos/mnt}"
WORK_DIR="${ARKOS_WORK_DIR:-/home/lcdyk/arkos}"
ARKOS_IMAGE_NAME="${ARKOS_IMAGE_NAME:-}"
UPDATE_DATE="$(TZ=Asia/Shanghai date +%m%d%Y)"
MODDER="kk&lcdyk"

RSYNC_BOOT_OPTS="-rltD --no-owner --no-group --no-perms --omit-dir-times"

safe() { "$@" 2>/dev/null || echo "[WARN] 失败: $*"; }

if [[ "$ARKOS_IMAGE_NAME" == *dArkOS* ]]; then
  # ============================================================
  # dArkOS 专用逻辑 (UID=1000)
  # ============================================================
  echo "=== 检测到 dArkOS 镜像，执行 dArkOS 专用注入 ==="
  CHOWN_USER="1000:1000"

  echo "== 注入 boot =="
  safe sudo mkdir -p "$MOUNT_DIR/boot/consoles"
  sudo rsync $RSYNC_BOOT_OPTS --exclude='files' ./consoles/ "$MOUNT_DIR/boot/consoles/"
  safe sudo rm -rf "$MOUNT_DIR/boot/consoles/logo"
  sudo mv "$MOUNT_DIR/boot/consoles/logo-darkos" "$MOUNT_DIR/boot/consoles/logo"
  safe sudo cp -f ./sh/clone.sh ./dtb_selector_macos ./dtb_selector_linux32 ./dtb_selector_win32.exe ./sh/expandtoexfat.sh "$MOUNT_DIR/boot/"
  safe sudo cp -f "$SCRIPT_DIR/sh/darkos-expandtoexfat.sh" "$MOUNT_DIR/boot/expandtoexfat.sh"

  echo "== 注入按键信息 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/home/ark/.quirks"
  safe sudo cp -r ./consoles/files/* "$MOUNT_DIR/root/home/ark/.quirks/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/home/ark/.quirks/"

  echo "== 注入 clone 用配置 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/usr/bin"
  safe sudo cp -f ./bin/mcu_led ./bin/ws2812 "$MOUNT_DIR/root/usr/bin/"
  safe sudo cp -f ./bin/sdljoymap ./bin/sdljoytest "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/console_detect "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/ws2812"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/mcu_led"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/sdljoytest"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/sdljoymap"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/console_detect"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/mcu_led" "$MOUNT_DIR/root/usr/bin/ws2812" "$MOUNT_DIR/root/usr/local/bin/sdljoytest" "$MOUNT_DIR/root/usr/local/bin/sdljoymap" "$MOUNT_DIR/root/usr/local/bin/console_detect"

  echo "== 替换 modules (root) =="
  SRC="./replace_file/modules"
  DST="$MOUNT_DIR/root/usr/lib/modules"
  if [[ -d "$SRC" ]]; then
    safe sudo mkdir -p "$DST"
    sudo rsync -a --delete "$SRC/" "$DST/"
    safe sudo chown -R $CHOWN_USER "$DST"
    safe sudo chmod -R 777 "$DST"
  else
    echo "[warn] $SRC not found, skip modules update"
  fi
  safe sudo depmod -a -b "$MOUNT_DIR/root" 4.4.189 2>/dev/null

  echo "== 添加 dArkOS 固件 =="
  FIRMWARE_SRC="$SCRIPT_DIR/replace_file/firmware"
  FIRMWARE_DST="$MOUNT_DIR/root/usr/lib/firmware"
  if [[ -d "$FIRMWARE_SRC" ]]; then
    safe sudo mkdir -p "$FIRMWARE_DST"
    safe sudo find "$FIRMWARE_DST" -type l -xtype l -delete 2>/dev/null
    safe sudo cp -rf "$FIRMWARE_SRC/." "$FIRMWARE_DST/"
    safe sudo chown -R root:root "$FIRMWARE_DST"
    safe sudo chmod -R 755 "$FIRMWARE_DST"
    safe sudo find "$FIRMWARE_DST" -type f -exec chmod 644 {} \;
    echo "固件更新完成"
  else
    echo "[warn] 固件源目录不存在: $FIRMWARE_SRC，跳过"
  fi

  echo "== 注入 915 固件 =="
  safe sudo cp -f ./bin/rk915/* "$MOUNT_DIR/root/usr/lib/firmware/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin 2>/dev/null

  echo "== 注入 swt6621s 固件 =="
  safe sudo cp -f ./bin/swt6621s/* "$MOUNT_DIR/root/usr/lib/firmware/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/"SWT6621S_*.bin 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/"SWT6621S_*.bin 2>/dev/null

  echo "== 注入 aic8800DC 固件 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC"
  safe sudo cp -f ./bin/aic8800DC/* "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC" 2>/dev/null

  echo "== 注入 351 系列手柄伪装规则  =="
  safe sudo cp -f ./bin/99-odroidgo3.rules "$MOUNT_DIR/root/etc/udev/rules.d" 2>/dev/null

  echo "== 注入 351Files 自适应 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/351Files/res"
  safe sudo cp -r ./res/* "$MOUNT_DIR/root/opt/351Files/res/" 2>/dev/null
  safe sudo cp -r ./replace_file/351Files "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null

  echo "== 注入 dArkOS 启动脚本 =="
  safe sudo cp -f ./replace_file/darkos4atomiswave.sh "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh"
  safe sudo cp -f ./replace_file/darkos4dreamcast.sh "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh"
  safe sudo cp -f ./replace_file/darkos4naomi.sh "$MOUNT_DIR/root/usr/local/bin/naomi.sh"
  safe sudo cp -f ./replace_file/darkos4n64.sh "$MOUNT_DIR/root/usr/local/bin/n64.sh"
  safe sudo cp -f ./replace_file/darkos4pico8.sh "$MOUNT_DIR/root/usr/local/bin/pico8.sh"
  safe sudo cp -f ./replace_file/darkos4saturn.sh "$MOUNT_DIR/root/usr/local/bin/saturn.sh"
  safe sudo cp -f ./replace_file/flash.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/drastic.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/drastic_kk.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/choose_drastic_ver.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/choose_ons_ver.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/onscripter.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/freej2me.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/darkos4get_last_played.sh "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/naomi.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/saturn.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/n64.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/flash.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/pico8.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/drastic.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/drastic_kk.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/choose_drastic_ver.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/choose_ons_ver.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/onscripter.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/freej2me.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/naomi.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/saturn.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/n64.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/flash.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pico8.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/drastic.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/drastic_kk.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/choose_drastic_ver.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/choose_ons_ver.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/onscripter.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/freej2me.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh" 2>/dev/null

  echo "== 注入 es-service 服务脚本 =="
  safe sudo cp -f ./bin/es-service/es-status-daemon.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/es-service/es-status-daemon.service "$MOUNT_DIR/root/etc/systemd/system/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/es-status-daemon.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/es-status-daemon.service" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/es-status-daemon.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/es-status-daemon.service" 2>/dev/null

  echo "== 注入 zram 服务脚本 =="
  safe sudo cp -f ./bin/zram-service/zram-setup.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/zram-service/zram-swap.service "$MOUNT_DIR/root/etc/systemd/system/"
  safe sudo cp -f ./bin/zram-service/zram.conf "$MOUNT_DIR/root/etc/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/zram-setup.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/zram-swap.service" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/zram.conf" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/zram-setup.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/zram-swap.service" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/zram.conf" 2>/dev/null

  echo "== 注入 batteryplus 服务脚本 =="
  safe sudo cp -f ./bin/batteryplus-service/batteryplus "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/batteryplus-service/batteryplus.service "$MOUNT_DIR/root/etc/systemd/system/"
  sudo mkdir -p "$MOUNT_DIR/root/etc/batteryplus/"
  safe sudo cp -f ./bin/batteryplus-service/batteryplus.conf "$MOUNT_DIR/root/etc/batteryplus/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/batteryplus" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/batteryplus.service" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/batteryplus/batteryplus.conf" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/batteryplus" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/batteryplus.service" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/batteryplus/batteryplus.conf" 2>/dev/null

  echo "== 添加 Gamma =="
  safe sudo cp -a ./replace_file/gamma/gamma "$MOUNT_DIR/usr/local/bin/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/usr/local/bin/gamma" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/usr/local/bin/gamma" 2>/dev/null

  echo "== 添加 Gamma =="
  safe sudo cp -a ./replace_file/gamma/gamma "$MOUNT_DIR/usr/local/bin/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/usr/local/bin/gamma" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/usr/local/bin/gamma" 2>/dev/null

  echo "== 注入核心 =="
  safe sudo cp -f ./mod_so/64/* "$MOUNT_DIR/root/home/ark/.config/retroarch/cores/"
  safe sudo cp -f ./mod_so/32/* "$MOUNT_DIR/root/home/ark/.config/retroarch32/cores/"
  safe sudo chown -R $CHOWN_USER $MOUNT_DIR/root/home/ark/.config/retroarch/cores/*
  safe sudo chown -R $CHOWN_USER $MOUNT_DIR/root/home/ark/.config/retroarch32/cores/*
  safe sudo chmod -R 777 $MOUNT_DIR/root/home/ark/.config/retroarch/cores/*
  safe sudo chmod -R 777 $MOUNT_DIR/root/home/ark/.config/retroarch32/cores/*

  echo "== 注入 dArkOS 主题配置 =="
  safe sudo cp -f ./replace_file/darkos4es_systems.cfg "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg"
  safe sudo cp -f ./replace_file/darkos4es_systems.cfg.dual "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual" 2>/dev/null
  safe sudo cp -rf ./replace_file/resources/* "$MOUNT_DIR/root/usr/bin/emulationstation/resources/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/emulationstation/resources"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/emulationstation/resources"
  safe sudo rm -rf "$MOUNT_DIR/root/etc/emulationstation/es_input.cfg" 2>/dev/null
  safe sudo cp -r ./replace_file/emulationstation "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"

  echo "== 还原 drastic =="
  safe sudo rm -rf "$MOUNT_DIR/root/opt/drastic" 2>/dev/null
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/drastic" 2>/dev/null
  safe sudo cp -a ./replace_file/drastic/. "$MOUNT_DIR/root/opt/drastic/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/drastic" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/drastic" 2>/dev/null

  echo "== 添加 drastic-kk =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/drastic-kk" 2>/dev/null
  safe sudo cp -a ./replace_file/drastic-kk/. "$MOUNT_DIR/root/opt/drastic-kk/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/drastic-kk" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/drastic-kk" 2>/dev/null
  safe sudo cp -f ./bin/json-c3/* "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/libjson-c.so"* 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/libjson-c.so"* 2>/dev/null

  echo "== 添加 onscripter-sa =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/onscripter" 2>/dev/null
  safe sudo cp -a ./replace_file/onscripter/. "$MOUNT_DIR/root/opt/onscripter/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/onscripter" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/onscripter" 2>/dev/null

  echo "== 添加 freej2me-sa =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/freej2mesa" 2>/dev/null
  safe sudo cp -a ./replace_file/freej2mesa/. "$MOUNT_DIR/root/opt/freej2mesa/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/freej2mesa" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/freej2mesa" 2>/dev/null

  echo "== 改用自适应分辨率 Retroarch 1.22.2 =="
  safe sudo cp -a ./replace_file/retroarch/retroarch "$MOUNT_DIR/root/opt/retroarch/bin/" 2>/dev/null
  safe sudo cp -a ./replace_file/retroarch/retroarch32 "$MOUNT_DIR/root/opt/retroarch/bin/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/retroarch/bin/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/retroarch/bin/" 2>/dev/null

  echo "== 更新和添加 flycastsa =="
  safe sudo cp -a ./replace_file/flycastsa/. "$MOUNT_DIR/root/opt/flycastsa/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/flycastsa/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/flycastsa/" 2>/dev/null

  echo "== 添加 ruffle-sa  =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/rufflesa" 2>/dev/null
  safe sudo cp -a ./replace_file/rufflesa/. "$MOUNT_DIR/root/opt/rufflesa/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/rufflesa" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/rufflesa" 2>/dev/null

  echo "== 更新和添加 yabasanshiro-sa =="
  safe sudo cp -a ./replace_file/yabasanshiro/. "$MOUNT_DIR/root/opt/yabasanshiro/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/yabasanshiro/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/yabasanshiro/" 2>/dev/null

  echo "== 处理 roms.tar =="
  if [ "$(stat -c%s $MOUNT_DIR/root/roms.tar 2>/dev/null || echo 0)" -le $((100*1024*1024)) ]; then
    echo "== 复制 roms.tar 出来操作 =="
    safe sudo cp "$MOUNT_DIR/root/roms.tar" "$WORK_DIR/"
    safe sudo mkdir -p "$WORK_DIR/tmproms"
    tar -xf "$WORK_DIR/roms.tar" -C "$WORK_DIR/tmproms"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/hbmame"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/native32"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/bbk"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/flash"
    tar -xf "$SCRIPT_DIR/zulu11.48.21-ca-jdk11.0.11-linux_aarch64.tar.gz" -C "$WORK_DIR/tmproms/roms/j2me"
    safe sudo mv "$WORK_DIR/tmproms/roms/j2me/zulu11.48.21-ca-jdk11.0.11-linux_aarch64" "$WORK_DIR/tmproms/roms/j2me/jdk"
    safe sudo chown -R root:root "$WORK_DIR/tmproms/roms/j2me/jdk"
    safe sudo chmod -R 777 "$WORK_DIR/tmproms/roms/j2me/jdk"
    echo "== 注入 portmaster =="
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/tools/PortMaster/"
    safe sudo cp -rf ./PortMaster/* "$WORK_DIR/tmproms/roms/tools/PortMaster/"
    safe sudo cp -rf ./bin/pm_libs/* "$WORK_DIR/tmproms/roms/tools/PortMaster/libs"
    safe sudo cp -rf ./PortMaster/PortMaster.sh "$WORK_DIR/tmproms/roms/tools/PortMaster.sh"
    # safe sudo chown -R $CHOWN_USER "$WORK_DIR/tmproms/roms/tools/PortMaster"
    safe sudo chown -R $CHOWN_USER "$WORK_DIR/tmproms/roms/tools/PortMaster.sh"
    safe sudo chmod -R 777 "$WORK_DIR/tmproms/roms/tools/PortMaster"
    safe sudo chmod -R 777 "$WORK_DIR/tmproms/roms/tools/PortMaster.sh"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/pymo"
    echo "== 注入 pymo 主题 =="
    safe sudo mkdir -p "$WORK_DIR/mnt/roms/themes/es-theme-nes-box/pymo"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/themes/es-theme-nes-box/pymo"
    safe sudo cp -r ./replace_file/pymo/pymo/* "$WORK_DIR/mnt/roms/themes/es-theme-nes-box/pymo"
    safe sudo chown -R root:root "$WORK_DIR/mnt/roms/themes/es-theme-nes-box/pymo"
    safe sudo chmod -R 777 "$WORK_DIR/mnt/roms/themes/es-theme-nes-box/pymo"
    safe sudo cp -r ./replace_file/pymo/pymo/* "$WORK_DIR/tmproms/roms/themes/es-theme-nes-box/pymo"
    safe sudo chown -R root:root "$WORK_DIR/tmproms/roms/themes/es-theme-nes-box/pymo"
    safe sudo chmod -R 777 "$WORK_DIR/tmproms/roms/themes/es-theme-nes-box/pymo"
    safe sudo rm "$WORK_DIR/tmproms/roms/tools/Install.PortMaster.sh"
    safe sudo cp -rf ./replace_file/pymo/Scan_for_new_games.pymo "$WORK_DIR/tmproms/roms/pymo/"
    safe sudo chown -R $CHOWN_USER "$WORK_DIR/tmproms/roms/pymo/Scan_for_new_games.pymo"
    safe sudo chmod -R 777 "$WORK_DIR/tmproms/roms/pymo/Scan_for_new_games.pymo"
    sudo tar -cf "$WORK_DIR/roms.tar" -C "$WORK_DIR/tmproms" .
    safe sudo rm -rf "$WORK_DIR/tmproms"
    safe sudo cp "$WORK_DIR/roms.tar" "$MOUNT_DIR/root/"
    safe sudo chmod -R 777 $MOUNT_DIR/root/roms.tar
    safe sudo rm -rf "$WORK_DIR/roms.tar"
  else
    echo "== 跳过 roms.tar 操作 =="
  fi

  echo "== 调整retrorun =="
  safe sudo cp -r ./replace_file/retrorun/* "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorun32"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorun"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorunsdl"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorunsdl32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorun32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorun"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorunsdl32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorunsdl"

  echo "== 注入pymo =="
  safe sudo cp -r ./replace_file/pymo/cpymo "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -r ./replace_file/pymo/pymo.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/cpymo"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/pymo.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/cpymo"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pymo.sh"

  echo "== ogage快捷键复制 =="
  safe sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/home/ark/.quirks/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/ogage"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/home/ark/.quirks/ogage"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/ogage"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/home/ark/.quirks/ogage"

  echo "== service的调整 =="
  safe sudo cp -r ./replace_file/services/351mp.service "$MOUNT_DIR/root/etc/systemd/system/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/351mp.service" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/351mp.service" 2>/dev/null
  safe sudo rm "$MOUNT_DIR/root/etc/systemd/system/batt_led.service" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/opt/system/Advanced/" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$MOUNT_DIR/root/opt/system/Advanced/" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Disable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Switch to main SD for Roms.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/Advanced/"*.sh 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Enable Quick Mode.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Disable Quick Mode.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Switch to main SD for Roms.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Switch to SD2 for Roms.sh" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/"*.sh 2>/dev/null

  echo "== 删除不需要的文件 =="
  safe sudo rm -rf "$MOUNT_DIR/boot/BMPs" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/boot/ScreenFiles" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/boot/boot.ini" $MOUNT_DIR/boot/*.dtb $MOUNT_DIR/boot/*.orig $MOUNT_DIR/boot/*.tony $MOUNT_DIR/boot/Image $MOUNT_DIR/boot/*.bmp $MOUNT_DIR/boot/WHERE_ARE_MY_ROMS.txt 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/boot/DTB Change Tool.exe" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/DeviceType" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Change LED to Red.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Update.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Wifi.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Network Info.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Enable Remote Services.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Disable Remote Services.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Change Time.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/NDS Overlays" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Change Ports SDL.sh" 2>/dev/null
  safe find "$MOUNT_DIR/root/opt/system/Advanced" -name 'Restore*.sh' ! -name 'Restore ArkOS Settings.sh' -exec rm -f {} + 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Screen - Switch to Original Screen Timings.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Reset EmulationStation Controls.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Fix Global Hotkeys.sh" 2>/dev/null

  echo "== 注入 dArkOS 工具 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/system/Tools/"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Backup dArkOS Settings" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Tools/Install.PortMaster.sh" 2>/dev/null
  safe sudo cp -r "./Jason3_Scripte/wifi-toggle/Wifi-toggle.sh" "$MOUNT_DIR/root/opt/system/Wifi-Toggle.sh"
  safe sudo cp -r "./Jason3_Scripte/InfoSystem/InfoSystem.sh" "$MOUNT_DIR/root/opt/system/Tools/System Info.sh"
  safe sudo cp -r "./Jason3_Scripte/GhostLoader/GhostLoader.sh" "$MOUNT_DIR/root/opt/system/Tools/Ghost Loader.sh"
  safe sudo cp -r "./Jason3_Scripte/Bluetooth-Manager/Bluetooth Manager.sh" "$MOUNT_DIR/root/opt/system/Tools/"
  safe sudo cp -r "./Jason3_Scripte/Bluetooth-Manager/patch.pak" "$MOUNT_DIR/root/opt/system/Tools/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/"*.sh
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/Tools/"*.sh
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/Advanced/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/Tools/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/Advanced/"*.sh

  echo "== 设置 dArkOS plymouth 标题 =="
  safe sudo sed -i "/title\=/c\title\=dArkOS4Clone ($UPDATE_DATE)($MODDER)" "$MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth"

else
  # ============================================================
  # ArkOS 专用逻辑 (UID=1002)
  # ============================================================
  echo "=== 检测到 ArkOS 镜像，执行 ArkOS 专用注入 ==="
  CHOWN_USER="1002:1002"

  echo "== 注入 boot =="
  safe sudo mkdir -p "$MOUNT_DIR/boot/consoles"
  sudo rsync $RSYNC_BOOT_OPTS --exclude='files' ./consoles/ "$MOUNT_DIR/boot/consoles/"
  safe sudo rm -rf "$MOUNT_DIR/boot/consoles/logo-darkos"
  safe sudo cp -f ./sh/clone.sh ./dtb_selector_macos ./dtb_selector_linux32 ./dtb_selector_win32.exe ./sh/expandtoexfat.sh "$MOUNT_DIR/boot/"

  echo "== 注入按键信息 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/home/ark/.quirks"
  safe sudo cp -r ./consoles/files/* "$MOUNT_DIR/root/home/ark/.quirks/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/home/ark/.quirks/"

  echo "== 注入 clone 用配置 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/usr/bin"
  safe sudo cp -f ./bin/mcu_led ./bin/ws2812 "$MOUNT_DIR/root/usr/bin/"
  safe sudo cp -f ./bin/sdljoymap ./bin/sdljoytest "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/console_detect "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/ws2812"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/mcu_led"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/sdljoytest"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/sdljoymap"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/console_detect"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/mcu_led" "$MOUNT_DIR/root/usr/bin/ws2812" "$MOUNT_DIR/root/usr/local/bin/sdljoytest" "$MOUNT_DIR/root/usr/local/bin/sdljoymap" "$MOUNT_DIR/root/usr/local/bin/console_detect"

  echo "== 替换 modules (root) =="
  SRC="./replace_file/modules"
  DST="$MOUNT_DIR/root/usr/lib/modules"
  if [[ -d "$SRC" ]]; then
    safe sudo mkdir -p "$DST"
    sudo rsync -a --delete "$SRC/" "$DST/"
    safe sudo chown -R $CHOWN_USER "$DST"
    safe sudo chmod -R 777 "$DST"
  else
    echo "[warn] $SRC not found, skip modules update"
  fi
  safe sudo depmod -a -b "$MOUNT_DIR/root" 4.4.189 2>/dev/null

  echo "== 注入 915 固件 =="
  safe sudo cp -f ./bin/rk915/rk915_*.bin "$MOUNT_DIR/root/usr/lib/firmware/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin 2>/dev/null

  echo "== 注入 swt6621s 固件 =="
  safe sudo cp -f ./bin/swt6621s/* "$MOUNT_DIR/root/usr/lib/firmware/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/"SWT6621S_*.bin 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/"SWT6621S_*.bin 2>/dev/null

  echo "== 注入 aic8800DC 固件 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC"
  safe sudo cp -f ./bin/aic8800DC/* "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC" 2>/dev/null

  echo "== 注入 351 系列手柄伪装规则  =="
  safe sudo cp -f ./bin/99-odroidgo3.rules "$MOUNT_DIR/root/etc/udev/rules.d" 2>/dev/null

  echo "== 注入 351Files 自适应 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/351Files/res"
  safe sudo cp -r ./res/* "$MOUNT_DIR/root/opt/351Files/res/" 2>/dev/null
  safe sudo cp -r ./replace_file/351Files "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/351Files/" 2>/dev/null

  echo "== 更新 usb-modeswitch-data =="
  safe sudo cp -a ./bin/usb-modeswitch-data/* "$MOUNT_DIR/root/" 2>/dev/null

  echo "== 注入 ArkOS 启动脚本 =="
  safe sudo cp -f ./replace_file/atomiswave.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/dreamcast.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/naomi.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/saturn.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/n64.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/mvem.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/gametank.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/easyrpg.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/gametankkeydemon.py "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/flash.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/pico8.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/drastic.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/drastic_kk.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/choose_drastic_ver.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/choose_ons_ver.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/onscripter.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/freej2me.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/mediaplayer.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./replace_file/get_last_played.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/naomi.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/saturn.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/n64.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/mvem.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/gametank.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/easyrpg.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/gametankkeydemon.py" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/flash.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/pico8.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/drastic.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/drastic_kk.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/choose_drastic_ver.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/choose_ons_ver.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/onscripter.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/freej2me.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/mediaplayer.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/naomi.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/saturn.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/n64.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/mvem.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/gametank.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/easyrpg.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/gametankkeydemon.py" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/flash.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pico8.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/drastic.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/drastic_kk.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/choose_drastic_ver.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/choose_ons_ver.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/onscripter.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/freej2me.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/mediaplayer.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh" 2>/dev/null

  echo "== 注入 es-service 服务脚本 =="
  safe sudo cp -f ./bin/es-service/es-status-daemon.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/es-service/es-status-daemon.service "$MOUNT_DIR/root/etc/systemd/system/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/es-status-daemon.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/es-status-daemon.service" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/es-status-daemon.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/es-status-daemon.service" 2>/dev/null

  echo "== 注入 zram 服务脚本 =="
  safe sudo cp -f ./bin/zram-service/zram-setup.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/zram-service/zram-swap.service "$MOUNT_DIR/root/etc/systemd/system/"
  safe sudo cp -f ./bin/zram-service/zram.conf "$MOUNT_DIR/root/etc/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/zram-setup.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/zram-swap.service" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/zram.conf" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/zram-setup.sh" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/zram-swap.service" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/zram.conf" 2>/dev/null

  echo "== 注入 batteryplus 服务脚本 =="
  safe sudo cp -f ./bin/batteryplus-service/batteryplus "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/batteryplus-service/batteryplus.service "$MOUNT_DIR/root/etc/systemd/system/"
  sudo mkdir -p "$MOUNT_DIR/root/etc/batteryplus/"
  safe sudo cp -f ./bin/batteryplus-service/batteryplus.conf "$MOUNT_DIR/root/etc/batteryplus/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/batteryplus" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/batteryplus.service" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/batteryplus/batteryplus.conf" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/batteryplus" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/batteryplus.service" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/batteryplus/batteryplus.conf" 2>/dev/null

  echo "== 注入核心 =="
  safe sudo cp -f ./mod_so/64/* "$MOUNT_DIR/root/home/ark/.config/retroarch/cores/"
  safe sudo cp -f ./mod_so/arkos_64/* "$MOUNT_DIR/root/home/ark/.config/retroarch/cores/"
  safe sudo cp -f ./mod_so/32/* "$MOUNT_DIR/root/home/ark/.config/retroarch32/cores/"
  safe sudo cp -f ./mod_so/arkos_32/* "$MOUNT_DIR/root/home/ark/.config/retroarch32/cores/"
  safe sudo chown -R $CHOWN_USER $MOUNT_DIR/root/home/ark/.config/retroarch/cores/*
  safe sudo chown -R $CHOWN_USER $MOUNT_DIR/root/home/ark/.config/retroarch32/cores/*
  safe sudo chmod -R 777 $MOUNT_DIR/root/home/ark/.config/retroarch/cores/*
  safe sudo chmod -R 777 $MOUNT_DIR/root/home/ark/.config/retroarch32/cores/*

  echo "== 注入 ArkOS 主题配置 =="
  safe sudo cp -f ./replace_file/es_systems.cfg "$MOUNT_DIR/root/etc/emulationstation/"
  safe sudo cp -f ./replace_file/es_systems.cfg.dual "$MOUNT_DIR/root/etc/emulationstation/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual" 2>/dev/null
  safe sudo cp -rf ./replace_file/resources/* "$MOUNT_DIR/root/usr/bin/emulationstation/resources/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/emulationstation/resources"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/emulationstation/resources"
  safe sudo rm -rf "$MOUNT_DIR/root/etc/emulationstation/es_input.cfg" 2>/dev/null
  safe sudo cp -r ./replace_file/emulationstation "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"

  echo "== 还原 drastic =="
  safe sudo rm -rf "$MOUNT_DIR/root/opt/drastic" 2>/dev/null
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/drastic" 2>/dev/null
  safe sudo cp -a ./replace_file/drastic/. "$MOUNT_DIR/root/opt/drastic/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/drastic" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/drastic" 2>/dev/null

  echo "== 添加 drastic-kk =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/drastic-kk" 2>/dev/null
  safe sudo cp -a ./replace_file/drastic-kk/. "$MOUNT_DIR/root/opt/drastic-kk/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/drastic-kk" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/drastic-kk" 2>/dev/null
  safe sudo cp -f ./bin/json-c3/* "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/libjson-c.so"* 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/libjson-c.so"* 2>/dev/null

  echo "== 添加 onscripter-sa =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/onscripter" 2>/dev/null
  safe sudo cp -a ./replace_file/onscripter/. "$MOUNT_DIR/root/opt/onscripter/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/onscripter" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/onscripter" 2>/dev/null

  echo "== 添加 freej2me-sa =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/freej2mesa" 2>/dev/null
  safe sudo cp -a ./replace_file/freej2mesa/. "$MOUNT_DIR/root/opt/freej2mesa/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/freej2mesa" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/freej2mesa" 2>/dev/null

  echo "== 改用自适应分辨率 Retroarch 1.22.2 =="
  safe sudo cp -a ./replace_file/retroarch/retroarch "$MOUNT_DIR/root/opt/retroarch/bin/" 2>/dev/null
  safe sudo cp -a ./replace_file/retroarch/retroarch32 "$MOUNT_DIR/root/opt/retroarch/bin/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/retroarch/bin/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/retroarch/bin/" 2>/dev/null

  echo "== 更新 Fake08-sa =="
  safe sudo cp -a ./replace_file/fake08/* "$MOUNT_DIR/root/opt/fake08/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/fake08/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/fake08/" 2>/dev/null

  echo "== 更新 PPSSPP 1.20.4 =="
  safe sudo cp -a ./replace_file/ppsspp/* "$MOUNT_DIR/root/opt/ppsspp/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/ppsspp/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/ppsspp/" 2>/dev/null

  echo "== 替换 PPSSPP-2021 =="
  safe sudo cp -a ./replace_file/ppsspp-2021/* "$MOUNT_DIR/root/opt/ppsspp-2021/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/ppsspp-2021/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/ppsspp-2021/" 2>/dev/null

  echo "== 更新 mupen64plus =="
  safe sudo cp -a ./replace_file/mupen64plus/* "$MOUNT_DIR/root/opt/mupen64plus/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/mupen64plus/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/mupen64plus/" 2>/dev/null

  echo "== 更新 ScummVM v2026.3.0 =="
  safe sudo cp -a ./replace_file/scummvm/* "$MOUNT_DIR/root/opt/scummvm/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/scummvm/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/scummvm/" 2>/dev/null

  echo "== 更新和添加 flycastsa =="
  safe sudo cp -a ./replace_file/flycastsa/. "$MOUNT_DIR/root/opt/flycastsa/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/flycastsa/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/flycastsa/" 2>/dev/null

  echo "== 更新 duckstation =="
  safe sudo cp -a ./replace_file/duckstation/. "$MOUNT_DIR/root/opt/duckstation/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/duckstation/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/duckstation/" 2>/dev/null

  echo "== 添加 gametank-sa  =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/gametank" 2>/dev/null
  safe sudo cp -a ./replace_file/gametank/. "$MOUNT_DIR/root/opt/gametank/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/gametank" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/gametank" 2>/dev/null

  echo "== 添加 ruffle-sa  =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/rufflesa" 2>/dev/null
  safe sudo cp -a ./replace_file/rufflesa/. "$MOUNT_DIR/root/opt/rufflesa/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/rufflesa" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/rufflesa" 2>/dev/null

  echo "== 更新和添加 yabasanshiro-sa =="
  safe sudo cp -a ./replace_file/yabasanshiro/. "$MOUNT_DIR/root/opt/yabasanshiro/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/yabasanshiro/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/yabasanshiro/" 2>/dev/null

  echo "== 更新 OpenborFF =="
  safe sudo cp -a ./replace_file/OpenBor/. "$MOUNT_DIR/root/opt/OpenBor/" 2>/dev/null
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/OpenBorFF" 2>/dev/null
  safe sudo cp -a ./replace_file/OpenBorFF/. "$MOUNT_DIR/root/opt/OpenBorFF/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/OpenBorFF/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/OpenBorFF/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/OpenBor/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/OpenBor/" 2>/dev/null

  echo "== 添加 krkr2 =="
  safe sudo cp -a ./replace_file/krkr2/. "$MOUNT_DIR/root/opt/krkr2/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/krkr2/" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/krkr2/" 2>/dev/null

  echo "== 处理 roms.tar =="
  if [ "$(stat -c%s $MOUNT_DIR/root/roms.tar 2>/dev/null || echo 0)" -le $((100*1024*1024)) ]; then
    echo "== 复制 roms.tar 出来操作 =="
    safe sudo cp "$MOUNT_DIR/root/roms.tar" "$WORK_DIR/"
    mkdir -p "$WORK_DIR/tmproms"
    tar -xf "$WORK_DIR/roms.tar" -C "$WORK_DIR/tmproms"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/hbmame"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/native32"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/bbk"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/gametank"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/pymo"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/flash"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/spmp8000"
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/krkr2"
    tar -xf "$SCRIPT_DIR/zulu11.48.21-ca-jdk11.0.11-linux_aarch64.tar.gz" -C "$WORK_DIR/tmproms/roms/j2me"
    safe sudo mv "$WORK_DIR/tmproms/roms/j2me/zulu11.48.21-ca-jdk11.0.11-linux_aarch64" "$WORK_DIR/tmproms/roms/j2me/jdk"
    safe sudo chown -R root:root "$WORK_DIR/tmproms/roms/j2me/jdk"
    safe sudo chmod -R 777 "$WORK_DIR/tmproms/roms/j2me/jdk"
    echo "== 注入 portmaster =="
    safe sudo mkdir -p "$WORK_DIR/tmproms/roms/tools/PortMaster/"
    safe sudo cp -rf ./PortMaster/* "$WORK_DIR/tmproms/roms/tools/PortMaster/"
    safe sudo cp -rf ./bin/pm_libs/* "$WORK_DIR/tmproms/roms/tools/PortMaster/libs"
    safe sudo cp -rf ./PortMaster/PortMaster.sh "$WORK_DIR/tmproms/roms/tools/PortMaster.sh"
    # safe sudo chown -R $CHOWN_USER "$WORK_DIR/tmproms/roms/tools/PortMaster"
    safe sudo chown -R $CHOWN_USER "$WORK_DIR/tmproms/roms/tools/PortMaster.sh"
    safe sudo chmod -R 777 "$WORK_DIR/tmproms/roms/tools/PortMaster"
    safe sudo chmod -R 777 "$WORK_DIR/tmproms/roms/tools/PortMaster.sh"
    echo "== 注入 pymo 主题 =="
    safe sudo cp -r ./replace_file/pymo/pymo "$MOUNT_DIR/root/tempthemes/es-theme-nes-box/"
    safe sudo chown -R root:root "$MOUNT_DIR/root/tempthemes/es-theme-nes-box/pymo"
    safe sudo chmod -R 777 "$MOUNT_DIR/root/tempthemes/es-theme-nes-box/pymo"
    safe sudo cp -rf ./replace_file/pymo/Scan_for_new_games.pymo "$WORK_DIR/tmproms/roms/pymo/"
    safe sudo chown -R $CHOWN_USER "$WORK_DIR/tmproms/roms/pymo/Scan_for_new_games.pymo"
    safe sudo chmod -R 777 "$WORK_DIR/tmproms/roms/pymo/Scan_for_new_games.pymo"
    sudo tar -cf "$WORK_DIR/roms.tar" -C "$WORK_DIR/tmproms" .
    safe sudo rm -rf "$WORK_DIR/tmproms"
    safe sudo cp "$WORK_DIR/roms.tar" "$MOUNT_DIR/root/"
    safe sudo chmod -R 777 $MOUNT_DIR/root/roms.tar
    safe sudo rm -rf "$WORK_DIR/roms.tar"
  else
    echo "== 跳过 roms.tar 操作 =="
  fi

  echo "== 调整retrorun =="
  safe sudo cp -r ./replace_file/retrorun/* "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorun32"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorun"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorunsdl"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorunsdl32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorun32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorun"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorunsdl32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorunsdl"

  echo "== 注入pymo =="
  safe sudo cp -r ./replace_file/pymo/cpymo "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -r ./replace_file/pymo/pymo.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/cpymo"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/pymo.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/cpymo"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pymo.sh"

  echo "== ogage快捷键复制 =="
  safe sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/home/ark/.quirks/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/ogage"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/home/ark/.quirks/ogage"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/ogage"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/home/ark/.quirks/ogage"

  echo "== service的调整 =="
  safe sudo cp -r ./replace_file/services/351mp.service "$MOUNT_DIR/root/etc/systemd/system/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/351mp.service" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/lib/systemd/system/mpv.service" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/351mp.service" 2>/dev/null
  safe sudo chmod 777 "$MOUNT_DIR/root/lib/systemd/system/mpv.service" 2>/dev/null
  safe sudo rm "$MOUNT_DIR/root/etc/systemd/system/batt_led.service" 2>/dev/null
  safe sudo rm "$MOUNT_DIR/root/etc/systemd/system/ddtbcheck.service" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/opt/system/Advanced/" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$MOUNT_DIR/root/opt/system/Advanced/" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Disable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Switch to main SD for Roms.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null
  safe sudo cp -r "./replace_file/tools/Switch to SD2 for Roms.sh" "$MOUNT_DIR/root/usr/local/bin/" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/Advanced/"*.sh 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Enable Quick Mode.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Disable Quick Mode.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Switch to main SD for Roms.sh" 2>/dev/null
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Switch to SD2 for Roms.sh" 2>/dev/null
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/"*.sh 2>/dev/null

  echo "== 删除logo随机 =="
  safe sudo sed -i '/imageshift\.sh/d' "$MOUNT_DIR/root/var/spool/cron/crontabs/root" 2>/dev/null
  safe sudo rm "$MOUNT_DIR/root/home/ark/.config/imageshift.sh" 2>/dev/null

  echo "== 删除不需要的文件 =="
  safe sudo rm -rf "$MOUNT_DIR/boot/BMPs" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/boot/ScreenFiles" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/boot/boot.ini" $MOUNT_DIR/boot/*.dtb $MOUNT_DIR/boot/*.orig $MOUNT_DIR/boot/*.tony $MOUNT_DIR/boot/Image $MOUNT_DIR/boot/*.bmp $MOUNT_DIR/boot/WHERE_ARE_MY_ROMS.txt 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/boot/DTB Change Tool.exe" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/DeviceType" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Change LED to Red.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Update.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Wifi.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Network Info.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Enable Remote Services.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Disable Remote Services.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Change Time.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/NDS Overlays" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Change Ports SDL.sh" 2>/dev/null
  safe find "$MOUNT_DIR/root/opt/system/Advanced" -name 'Restore*.sh' ! -name 'Restore ArkOS Settings.sh' -exec rm -f {} + 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Screen - Switch to Original Screen Timings.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Reset EmulationStation Controls.sh" 2>/dev/null
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Fix Global Hotkeys.sh" 2>/dev/null

  echo "== 注入工具 =="
  safe sudo cp -r "./Jason3_Scripte/wifi-toggle/Wifi-toggle.sh" "$MOUNT_DIR/root/opt/system/Wifi-Toggle.sh"
  safe sudo cp -r "./Jason3_Scripte/InfoSystem/InfoSystem.sh" "$MOUNT_DIR/root/opt/system/Tools/System Info.sh"
  safe sudo cp -r "./Jason3_Scripte/GhostLoader/GhostLoader.sh" "$MOUNT_DIR/root/opt/system/Tools/Ghost Loader.sh"
  safe sudo cp -r "./Jason3_Scripte/Bluetooth-Manager/Bluetooth Manager.sh" "$MOUNT_DIR/root/opt/system/Tools/"
  safe sudo cp -r "./Jason3_Scripte/Bluetooth-Manager/patch.pak" "$MOUNT_DIR/root/opt/system/Tools/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/"*.sh
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/Tools/"*.sh
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/Advanced/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/Tools/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/Advanced/"*.sh

  echo "== 设置 ArkOS plymouth 标题 =="
  safe sudo sed -i "/title\=/c\title\=ArkOS4Clone ($UPDATE_DATE)($MODDER)" "$MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth"
fi

safe sudo touch $MOUNT_DIR/boot/"USE_DTB_SELECT_TO_SELECT_DEVICE" 2>/dev/null
cat $MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth
echo "== 完成 =="
