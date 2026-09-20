#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNT_DIR="${ARKOS_MNT:-/home/lcdyk/arkos/mnt}"
WORK_DIR="${ARKOS_WORK_DIR:-/home/lcdyk/arkos}"
ARKOS_IMAGE_NAME="${ARKOS_IMAGE_NAME:-}"
UPDATE_DATE="$(TZ=Asia/Shanghai date +%Y%m%d)"
MODDER="kk&lcdyk"

RSYNC_BOOT_OPTS="-rltD --no-owner --no-group --no-perms --omit-dir-times"

# safe: 尽力而为的操作，失败保留现场并在结尾判定构建失败
FAIL_COUNT=0
safe() {
  if ! "$@"; then
    echo "[WARN] 失败: $*"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# fatal: 关键写入 (镜像内容注入)，失败立即中止构建，避免产出损坏镜像
fatal() {
  if ! "$@"; then
    echo "[ERROR] 致命失败: $*"
    exit 1
  fi
}

# require_space_mb: 镜像 root 分区剩余空间 (MB) 不足 need 时直接报错退出
require_space_mb() {
  local need="$1" avail
  avail="$(df -Pm "$MOUNT_DIR/root" 2>/dev/null | awk 'NR==2{print $4}')"
  if [[ -z "$avail" ]] || (( avail < need )); then
    echo "[ERROR] 镜像 root 分区空间不足: 需要 ${need}MB，实际剩余 ${avail:-未知}MB"
    exit 1
  fi
}

echo "== 注入前镜像 root 分区剩余空间 =="
df -h "$MOUNT_DIR/root" || true

echo "== 解压大型核心 (如有) =="
# 超过 GitHub 100MB 限制的核心以 .so.xz 入库，复制核心前先解压 (已解压过则跳过)
for CORE_DIR in ./mod_so/64 ./mod_so/32 ./mod_so/arkos_64 ./mod_so/arkos_32; do
  for CORE_XZ in "$CORE_DIR"/*.so.xz; do
    [[ -e "$CORE_XZ" ]] || continue
    CORE_SO="${CORE_XZ%.xz}"
    if [[ ! -f "$CORE_SO" ]]; then
      echo "解压 $CORE_XZ"
      fatal xz -dk -T0 "$CORE_XZ"
    fi
  done
done

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
  safe sudo depmod -a -b "$MOUNT_DIR/root" 4.4.189

  echo "== 添加 dArkOS 固件 =="
  FIRMWARE_SRC="$SCRIPT_DIR/replace_file/firmware"
  FIRMWARE_DST="$MOUNT_DIR/root/usr/lib/firmware"
  if [[ -d "$FIRMWARE_SRC" ]]; then
    safe sudo mkdir -p "$FIRMWARE_DST"
    safe sudo find "$FIRMWARE_DST" -type l -xtype l -delete
    safe sudo cp -rf "$FIRMWARE_SRC/." "$FIRMWARE_DST/"
    safe sudo chown -R root:root "$FIRMWARE_DST"
    safe sudo chmod -R 755 "$FIRMWARE_DST"
    safe sudo find "$FIRMWARE_DST" -type f -exec chmod 644 {} \;
    echo "固件更新完成"
  else
    echo "[warn] 固件源目录不存在: $FIRMWARE_SRC，跳过"
  fi

  echo "== 注入 915 固件 =="
  safe sudo cp -f ./bin/rk915/* "$MOUNT_DIR/root/usr/lib/firmware/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin

  echo "== 注入 swt6621s 固件 =="
  safe sudo cp -f ./bin/swt6621s/* "$MOUNT_DIR/root/usr/lib/firmware/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/"SWT6621S_*.bin
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/"SWT6621S_*.bin

  echo "== 注入 aic8800DC 固件 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC"
  safe sudo cp -f ./bin/aic8800DC/* "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC"

  echo "== 注入 351 系列手柄伪装规则  =="
  safe sudo cp -f ./bin/99-odroidgo3.rules "$MOUNT_DIR/root/etc/udev/rules.d"

  echo "== 注入 351Files 自适应 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/351Files/res"
  safe sudo cp -r ./replace_file/351Files/. "$MOUNT_DIR/root/opt/351Files/" 
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/351Files/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/351Files/"

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
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/naomi.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/saturn.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/n64.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/flash.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/pico8.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/drastic.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/drastic_kk.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/choose_drastic_ver.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/choose_ons_ver.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/onscripter.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/freej2me.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/naomi.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/saturn.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/n64.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/flash.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pico8.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/drastic.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/drastic_kk.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/choose_drastic_ver.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/choose_ons_ver.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/onscripter.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/freej2me.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh"

  echo "== 注入 es-service 服务脚本 =="
  safe sudo cp -f ./bin/es-service/es-status-daemon.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/es-service/es-status-daemon.service "$MOUNT_DIR/root/etc/systemd/system/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/es-status-daemon.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/es-status-daemon.service"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/es-status-daemon.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/es-status-daemon.service"

  echo "== 注入 zram 服务脚本 =="
  safe sudo cp -f ./bin/zram-service/zram-setup.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/zram-service/zram-swap.service "$MOUNT_DIR/root/etc/systemd/system/"
  safe sudo cp -f ./bin/zram-service/zram.conf "$MOUNT_DIR/root/etc/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/zram-setup.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/zram-swap.service"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/zram.conf"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/zram-setup.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/zram-swap.service"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/zram.conf"

  echo "== 注入 batteryplus 服务脚本 =="
  safe sudo cp -f ./bin/batteryplus-service/batteryplus "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/batteryplus-service/batteryplus.service "$MOUNT_DIR/root/etc/systemd/system/"
  sudo mkdir -p "$MOUNT_DIR/root/etc/batteryplus/"
  safe sudo cp -f ./bin/batteryplus-service/batteryplus.conf "$MOUNT_DIR/root/etc/batteryplus/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/batteryplus"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/batteryplus.service"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/batteryplus/batteryplus.conf"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/batteryplus"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/batteryplus.service"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/batteryplus/batteryplus.conf"

  echo "== 添加 Gamma =="
  safe sudo cp -a ./replace_file/gamma/gamma "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/gamma"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/gamma"

  echo "== 注入核心 =="
  safe sudo cp -f ./mod_so/64/* "$MOUNT_DIR/root/home/ark/.config/retroarch/cores/"
  safe sudo cp -f ./mod_so/32/* "$MOUNT_DIR/root/home/ark/.config/retroarch32/cores/"
  safe sudo chown -R $CHOWN_USER $MOUNT_DIR/root/home/ark/.config/retroarch/cores/*
  safe sudo chown -R $CHOWN_USER $MOUNT_DIR/root/home/ark/.config/retroarch32/cores/*
  safe sudo chmod -R 777 $MOUNT_DIR/root/home/ark/.config/retroarch/cores/*
  safe sudo chmod -R 777 $MOUNT_DIR/root/home/ark/.config/retroarch32/cores/*

  echo "== 注入 dArkOS 主题配置 =="
  safe sudo cp -f ./replace_file/darkos4es_systems.cfg "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg"
  safe sudo cp -f ./replace_file/darkos4es_systems.cfg.sd1 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.sd1"
  safe sudo cp -f ./replace_file/darkos4es_systems.cfg.sd2 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.sd2"
  safe sudo cp -f ./replace_file/darkos4es_systems.cfg.dual "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.sd1"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.sd2"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.sd1"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.sd2"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual"
  safe sudo cp -rf ./replace_file/resources/* "$MOUNT_DIR/root/usr/bin/emulationstation/resources/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/emulationstation/resources"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/emulationstation/resources"
  safe sudo rm -rf "$MOUNT_DIR/root/etc/emulationstation/es_input.cfg"
  safe sudo cp -r ./replace_file/emulationstation "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"

  echo "== 还原 drastic =="
  safe sudo rm -rf "$MOUNT_DIR/root/opt/drastic"
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/drastic"
  safe sudo cp -a ./replace_file/drastic/. "$MOUNT_DIR/root/opt/drastic/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/drastic"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/drastic"

  echo "== 添加 drastic-kk =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/drastic-kk"
  safe sudo cp -a ./replace_file/drastic-kk/. "$MOUNT_DIR/root/opt/drastic-kk/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/drastic-kk"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/drastic-kk"
  safe sudo cp -f ./bin/json-c3/* "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/libjson-c.so"*
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/libjson-c.so"*

  echo "== 添加 onscripter-sa =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/onscripter"
  safe sudo cp -a ./replace_file/onscripter/. "$MOUNT_DIR/root/opt/onscripter/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/onscripter"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/onscripter"

  echo "== 添加 freej2me-sa =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/freej2mesa"
  safe sudo cp -a ./replace_file/freej2mesa/. "$MOUNT_DIR/root/opt/freej2mesa/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/freej2mesa"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/freej2mesa"

  echo "== 改用自适应分辨率 Retroarch 1.22.2 =="
  safe sudo cp -a ./replace_file/retroarch/retroarch "$MOUNT_DIR/root/opt/retroarch/bin/"
  safe sudo cp -a ./replace_file/retroarch/retroarch32 "$MOUNT_DIR/root/opt/retroarch/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/retroarch/bin/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/retroarch/bin/"

  echo "== 更新和添加 flycastsa =="
  safe sudo cp -a ./replace_file/flycastsa/. "$MOUNT_DIR/root/opt/flycastsa/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/flycastsa/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/flycastsa/"

  echo "== 添加 ruffle-sa  =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/rufflesa"
  safe sudo cp -a ./replace_file/rufflesa/. "$MOUNT_DIR/root/opt/rufflesa/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/rufflesa"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/rufflesa"

  echo "== 更新和添加 yabasanshiro-sa =="
  safe sudo cp -a ./replace_file/yabasanshiro/. "$MOUNT_DIR/root/opt/yabasanshiro/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/yabasanshiro/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/yabasanshiro/"

  echo "== 处理 roms.tar =="
  if [ "$(stat -c%s $MOUNT_DIR/root/roms.tar 2>/dev/null || echo 0)" -le $((100*1024*1024)) ]; then
    echo "== 复制 roms.tar 出来操作 =="
    fatal sudo cp "$MOUNT_DIR/root/roms.tar" "$WORK_DIR/"
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
    safe sudo rm -f "$WORK_DIR/tmproms/roms/tools/Install.PortMaster.sh"
    safe sudo cp -rf ./replace_file/pymo/Scan_for_new_games.pymo "$WORK_DIR/tmproms/roms/pymo/"
    safe sudo chown -R $CHOWN_USER "$WORK_DIR/tmproms/roms/pymo/Scan_for_new_games.pymo"
    safe sudo chmod -R 777 "$WORK_DIR/tmproms/roms/pymo/Scan_for_new_games.pymo"
    sudo tar -cf "$WORK_DIR/roms.tar" -C "$WORK_DIR/tmproms" .
    safe sudo rm -rf "$WORK_DIR/tmproms"
    # 回拷前确认 p2 放得下 (roms.tar 大小 + 200MB 余量)，放不下直接中止
    TAR_MB=$(( $(stat -c%s "$WORK_DIR/roms.tar" 2>/dev/null || echo 0) / 1024 / 1024 ))
    require_space_mb $(( TAR_MB + 200 ))
    fatal sudo cp "$WORK_DIR/roms.tar" "$MOUNT_DIR/root/"
    safe sudo chmod -R 777 $MOUNT_DIR/root/roms.tar
    safe sudo rm -rf "$WORK_DIR/roms.tar"
  else
    echo "== 跳过 roms.tar 操作 =="
  fi

  echo "== 调整retrorun =="
  fatal sudo cp -r ./replace_file/retrorun/* "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorun32"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorun"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorunsdl"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorunsdl32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorun32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorun"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorunsdl32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorunsdl"

  echo "== 注入pymo =="
  fatal sudo cp -r ./replace_file/pymo/cpymo "$MOUNT_DIR/root/usr/local/bin/"
  fatal sudo cp -r ./replace_file/pymo/pymo.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/cpymo"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/pymo.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/cpymo"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pymo.sh"

  echo "== ogage快捷键复制 =="
  fatal sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/usr/local/bin/"
  fatal sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/home/ark/.quirks/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/ogage"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/home/ark/.quirks/ogage"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/ogage"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/home/ark/.quirks/ogage"

  echo "== service的调整 =="
  safe sudo cp -r ./replace_file/services/351mp.service "$MOUNT_DIR/root/etc/systemd/system/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/351mp.service"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/351mp.service"
  safe sudo rm -f "$MOUNT_DIR/root/etc/systemd/system/batt_led.service"
  safe sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/opt/system/Advanced/"
  safe sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/opt/system/Advanced/"
  safe sudo cp -r "./replace_file/tools/351Files.sh" "$MOUNT_DIR/root/opt/system/"
  safe sudo cp -r "./replace_file/tools/Disable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/"*.sh
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Enable Quick Mode.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Disable Quick Mode.sh"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/"*.sh

  echo "== 删除不需要的文件 =="
  safe sudo rm -rf "$MOUNT_DIR/boot/BMPs"
  safe sudo rm -rf "$MOUNT_DIR/boot/ScreenFiles"
  safe sudo rm -rf "$MOUNT_DIR/boot/boot.ini" $MOUNT_DIR/boot/*.dtb $MOUNT_DIR/boot/*.orig $MOUNT_DIR/boot/*.tony $MOUNT_DIR/boot/Image $MOUNT_DIR/boot/*.bmp $MOUNT_DIR/boot/WHERE_ARE_MY_ROMS.txt
  safe sudo rm -rf "$MOUNT_DIR/boot/DTB Change Tool.exe"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/DeviceType"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Change LED to Red.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Update.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Wifi.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Network Info.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Enable Remote Services.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Disable Remote Services.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Change Time.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/NDS Overlays"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Change Ports SDL.sh"
  safe find "$MOUNT_DIR/root/opt/system/Advanced" -name 'Restore*.sh' ! -name 'Restore ArkOS Settings.sh' -exec rm -f {} +
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Screen - Switch to Original Screen Timings.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Reset EmulationStation Controls.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Fix Global Hotkeys.sh"

  echo "== 注入 dArkOS 工具 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/system/Tools/"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Backup dArkOS Settings"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Tools/Install.PortMaster.sh"
  fatal sudo cp -r "./Jason3_Scripte/wifi-toggle/Wifi-toggle.sh" "$MOUNT_DIR/root/opt/system/Wifi-Toggle.sh"
  fatal sudo cp -r "./Jason3_Scripte/InfoSystem/InfoSystem.sh" "$MOUNT_DIR/root/opt/system/Tools/System Info.sh"
  fatal sudo cp -r "./Jason3_Scripte/GhostLoader/GhostLoader.sh" "$MOUNT_DIR/root/opt/system/Tools/Ghost Loader.sh"
  fatal sudo cp -r "./Jason3_Scripte/Bluetooth-Manager/Bluetooth Manager.sh" "$MOUNT_DIR/root/opt/system/Tools/"
  fatal sudo cp -r "./Jason3_Scripte/Bluetooth-Manager/patch.pak" "$MOUNT_DIR/root/opt/system/Tools/"
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
  safe sudo depmod -a -b "$MOUNT_DIR/root" 4.4.189

  echo "== 注入 915 固件 =="
  safe sudo cp -f ./bin/rk915/rk915_*.bin "$MOUNT_DIR/root/usr/lib/firmware/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/"rk915_*.bin

  echo "== 注入 swt6621s 固件 =="
  safe sudo cp -f ./bin/swt6621s/* "$MOUNT_DIR/root/usr/lib/firmware/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/"SWT6621S_*.bin
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/"SWT6621S_*.bin

  echo "== 注入 aic8800DC 固件 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC"
  safe sudo cp -f ./bin/aic8800DC/* "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/firmware/aic8800DC"

  echo "== 注入 351 系列手柄伪装规则  =="
  safe sudo cp -f ./bin/99-odroidgo3.rules "$MOUNT_DIR/root/etc/udev/rules.d"

  echo "== 注入 351Files 自适应 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/351Files/res"
  safe sudo cp -r ./replace_file/351Files/. "$MOUNT_DIR/root/opt/351Files/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/351Files/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/351Files/"

  echo "== 更新 usb-modeswitch-data =="
  safe sudo cp -a ./bin/usb-modeswitch-data/* "$MOUNT_DIR/root/"

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
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/naomi.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/saturn.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/n64.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/mvem.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/gametank.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/easyrpg.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/gametankkeydemon.py"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/flash.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/pico8.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/drastic.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/drastic_kk.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/choose_drastic_ver.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/choose_ons_ver.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/onscripter.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/freej2me.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/mediaplayer.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/atomiswave.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/dreamcast.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/naomi.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/saturn.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/n64.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/mvem.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/gametank.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/easyrpg.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/gametankkeydemon.py"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/flash.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pico8.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/drastic.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/drastic_kk.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/choose_drastic_ver.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/choose_ons_ver.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/onscripter.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/freej2me.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/mediaplayer.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/get_last_played.sh"

  echo "== 注入 es-service 服务脚本 =="
  safe sudo cp -f ./bin/es-service/es-status-daemon.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/es-service/es-status-daemon.service "$MOUNT_DIR/root/etc/systemd/system/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/es-status-daemon.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/es-status-daemon.service"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/es-status-daemon.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/es-status-daemon.service"

  echo "== 注入 zram 服务脚本 =="
  safe sudo cp -f ./bin/zram-service/zram-setup.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/zram-service/zram-swap.service "$MOUNT_DIR/root/etc/systemd/system/"
  safe sudo cp -f ./bin/zram-service/zram.conf "$MOUNT_DIR/root/etc/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/zram-setup.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/zram-swap.service"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/zram.conf"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/zram-setup.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/zram-swap.service"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/zram.conf"

  echo "== 注入 batteryplus 服务脚本 =="
  safe sudo cp -f ./bin/batteryplus-service/batteryplus "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -f ./bin/batteryplus-service/batteryplus.service "$MOUNT_DIR/root/etc/systemd/system/"
  sudo mkdir -p "$MOUNT_DIR/root/etc/batteryplus/"
  safe sudo cp -f ./bin/batteryplus-service/batteryplus.conf "$MOUNT_DIR/root/etc/batteryplus/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/batteryplus"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/batteryplus.service"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/batteryplus/batteryplus.conf"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/batteryplus"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/batteryplus.service"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/batteryplus/batteryplus.conf"

  echo "== 添加 Gamma =="
  safe sudo cp -a ./replace_file/gamma/gamma "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/gamma"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/gamma"

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
  safe sudo cp -f ./replace_file/es_systems.cfg.sd1 "$MOUNT_DIR/root/etc/emulationstation/"
  safe sudo cp -f ./replace_file/es_systems.cfg.sd2 "$MOUNT_DIR/root/etc/emulationstation/"
  safe sudo cp -f ./replace_file/es_systems.cfg.dual "$MOUNT_DIR/root/etc/emulationstation/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.sd1"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.sd2"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.sd1"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.sd2"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/emulationstation/es_systems.cfg.dual"
  safe sudo cp -rf ./replace_file/resources/* "$MOUNT_DIR/root/usr/bin/emulationstation/resources/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/emulationstation/resources"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/emulationstation/resources"
  safe sudo rm -rf "$MOUNT_DIR/root/etc/emulationstation/es_input.cfg"
  safe sudo cp -r ./replace_file/emulationstation "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/bin/emulationstation/emulationstation"

  echo "== 还原 drastic =="
  safe sudo rm -rf "$MOUNT_DIR/root/opt/drastic"
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/drastic"
  safe sudo cp -a ./replace_file/drastic/. "$MOUNT_DIR/root/opt/drastic/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/drastic"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/drastic"

  echo "== 添加 drastic-kk =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/drastic-kk"
  safe sudo cp -a ./replace_file/drastic-kk/. "$MOUNT_DIR/root/opt/drastic-kk/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/drastic-kk"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/drastic-kk"
  safe sudo cp -f ./bin/json-c3/* "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/libjson-c.so"*
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/lib/aarch64-linux-gnu/libjson-c.so"*

  echo "== 添加 DSperate-sa =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/DSperate"
  safe sudo cp -a ./replace_file/DSperate/. "$MOUNT_DIR/root/opt/DSperate/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/DSperate"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/DSperate"

  echo "== 添加 glibc242 =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/glibc-2.42"
  safe sudo cp -a ./replace_file/glibc-2.42/. "$MOUNT_DIR/root/opt/glibc-2.42/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/glibc-2.42"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/glibc-2.42"
  safe sudo cp -a ./replace_file/glibc242 "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/glibc242"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/glibc242"
  safe sudo cp -a ./replace_file/retroarch.sh "$MOUNT_DIR/root/usr/local/bin/retroarch"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retroarch"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retroarch"

  echo "== 添加 onscripter-sa =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/onscripter"
  safe sudo cp -a ./replace_file/onscripter/. "$MOUNT_DIR/root/opt/onscripter/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/onscripter"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/onscripter"

  echo "== 添加 freej2me-sa =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/freej2mesa"
  safe sudo cp -a ./replace_file/freej2mesa/. "$MOUNT_DIR/root/opt/freej2mesa/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/freej2mesa"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/freej2mesa"

  echo "== 改用自适应分辨率 Retroarch 1.22.2 =="
  safe sudo cp -a ./replace_file/retroarch/retroarch "$MOUNT_DIR/root/opt/retroarch/bin/"
  safe sudo cp -a ./replace_file/retroarch/retroarch32 "$MOUNT_DIR/root/opt/retroarch/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/retroarch/bin/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/retroarch/bin/"

  echo "== 更新 Fake08-sa =="
  safe sudo cp -a ./replace_file/fake08/* "$MOUNT_DIR/root/opt/fake08/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/fake08/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/fake08/"

  echo "== 更新 PPSSPP 1.20.4 =="
  safe sudo cp -a ./replace_file/ppsspp/* "$MOUNT_DIR/root/opt/ppsspp/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/ppsspp/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/ppsspp/"

  echo "== 替换 PPSSPP-2021 =="
  safe sudo cp -a ./replace_file/ppsspp-2021/* "$MOUNT_DIR/root/opt/ppsspp-2021/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/ppsspp-2021/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/ppsspp-2021/"

  echo "== 更新 mupen64plus =="
  safe sudo cp -a ./replace_file/mupen64plus/* "$MOUNT_DIR/root/opt/mupen64plus/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/mupen64plus/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/mupen64plus/"

  echo "== 更新 ScummVM v2026.3.0 =="
  safe sudo cp -a ./replace_file/scummvm/* "$MOUNT_DIR/root/opt/scummvm/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/scummvm/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/scummvm/"

  echo "== 更新和添加 flycastsa =="
  safe sudo cp -a ./replace_file/flycastsa/. "$MOUNT_DIR/root/opt/flycastsa/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/flycastsa/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/flycastsa/"

  echo "== 更新 duckstation =="
  safe sudo cp -a ./replace_file/duckstation/. "$MOUNT_DIR/root/opt/duckstation/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/duckstation/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/duckstation/"

  echo "== 添加 gametank-sa  =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/gametank"
  safe sudo cp -a ./replace_file/gametank/. "$MOUNT_DIR/root/opt/gametank/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/gametank"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/gametank"

  echo "== 添加 ruffle-sa  =="
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/rufflesa"
  safe sudo cp -a ./replace_file/rufflesa/. "$MOUNT_DIR/root/opt/rufflesa/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/rufflesa"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/rufflesa"

  echo "== 更新和添加 yabasanshiro-sa =="
  safe sudo cp -a ./replace_file/yabasanshiro/. "$MOUNT_DIR/root/opt/yabasanshiro/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/yabasanshiro/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/yabasanshiro/"

  echo "== 更新 OpenborFF =="
  safe sudo cp -a ./replace_file/OpenBor/. "$MOUNT_DIR/root/opt/OpenBor/"
  safe sudo mkdir -p "$MOUNT_DIR/root/opt/OpenBorFF"
  safe sudo cp -a ./replace_file/OpenBorFF/. "$MOUNT_DIR/root/opt/OpenBorFF/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/OpenBorFF/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/OpenBorFF/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/OpenBor/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/OpenBor/"

  echo "== 添加 krkr2 =="
  safe sudo cp -a ./replace_file/krkr2/. "$MOUNT_DIR/root/opt/krkr2/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/krkr2/"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/krkr2/"

  echo "== 处理 roms.tar =="
  if [ "$(stat -c%s $MOUNT_DIR/root/roms.tar 2>/dev/null || echo 0)" -le $((100*1024*1024)) ]; then
    echo "== 复制 roms.tar 出来操作 =="
    fatal sudo cp "$MOUNT_DIR/root/roms.tar" "$WORK_DIR/"
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
    # 回拷前确认 p2 放得下 (roms.tar 大小 + 200MB 余量)，放不下直接中止
    TAR_MB=$(( $(stat -c%s "$WORK_DIR/roms.tar" 2>/dev/null || echo 0) / 1024 / 1024 ))
    require_space_mb $(( TAR_MB + 200 ))
    fatal sudo cp "$WORK_DIR/roms.tar" "$MOUNT_DIR/root/"
    safe sudo chmod -R 777 $MOUNT_DIR/root/roms.tar
    safe sudo rm -rf "$WORK_DIR/roms.tar"
  else
    echo "== 跳过 roms.tar 操作 =="
  fi

  echo "== 调整retrorun =="
  fatal sudo cp -r ./replace_file/retrorun/* "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorun32"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorun"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorunsdl"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/retrorunsdl32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorun32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorun"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorunsdl32"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/retrorunsdl"

  echo "== 注入pymo =="
  fatal sudo cp -r ./replace_file/pymo/cpymo "$MOUNT_DIR/root/usr/local/bin/"
  fatal sudo cp -r ./replace_file/pymo/pymo.sh "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/cpymo"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/pymo.sh"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/cpymo"
  safe sudo chmod 777 "$MOUNT_DIR/root/usr/local/bin/pymo.sh"

  echo "== ogage快捷键复制 =="
  fatal sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/usr/local/bin/"
  fatal sudo cp -r ./replace_file/ogage "$MOUNT_DIR/root/home/ark/.quirks/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/ogage"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/home/ark/.quirks/ogage"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/ogage"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/home/ark/.quirks/ogage"

  echo "== service的调整 =="
  safe sudo cp -r ./replace_file/services/351mp.service "$MOUNT_DIR/root/etc/systemd/system/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/etc/systemd/system/351mp.service"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/lib/systemd/system/mpv.service"
  safe sudo chmod 777 "$MOUNT_DIR/root/etc/systemd/system/351mp.service"
  safe sudo chmod 777 "$MOUNT_DIR/root/lib/systemd/system/mpv.service"
  safe sudo rm -f "$MOUNT_DIR/root/etc/systemd/system/batt_led.service"
  safe sudo rm -f "$MOUNT_DIR/root/etc/systemd/system/ddtbcheck.service"
  safe sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/opt/system/Advanced/"
  safe sudo cp -r "./replace_file/tools/351Files.sh" "$MOUNT_DIR/root/opt/system/"
  safe sudo cp -r "./replace_file/tools/Enable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo cp -r "./replace_file/tools/Disable Quick Mode.sh" "$MOUNT_DIR/root/usr/local/bin/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/"*.sh
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Enable Quick Mode.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/usr/local/bin/Disable Quick Mode.sh"
  safe sudo chmod -R 777 "$MOUNT_DIR/root/usr/local/bin/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/"*.sh

  echo "== 删除logo随机 =="
  safe sudo sed -i '/imageshift\.sh/d' "$MOUNT_DIR/root/var/spool/cron/crontabs/root"
  safe sudo rm -f "$MOUNT_DIR/root/home/ark/.config/imageshift.sh"

  echo "== 删除不需要的文件 =="
  safe sudo rm -rf "$MOUNT_DIR/boot/BMPs"
  safe sudo rm -rf "$MOUNT_DIR/boot/ScreenFiles"
  safe sudo rm -rf "$MOUNT_DIR/boot/boot.ini" $MOUNT_DIR/boot/*.dtb $MOUNT_DIR/boot/*.orig $MOUNT_DIR/boot/*.tony $MOUNT_DIR/boot/Image $MOUNT_DIR/boot/*.bmp $MOUNT_DIR/boot/WHERE_ARE_MY_ROMS.txt
  safe sudo rm -rf "$MOUNT_DIR/boot/DTB Change Tool.exe"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/DeviceType"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Change LED to Red.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Update.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Read from SD1 and SD2 for Roms"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Read from SD1 and SD2 for Roms.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Switch to SD2 for Roms.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Switch to main SD for Roms.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/usr/local/bin/Read from SD1 and SD2 for Roms"
  safe sudo rm -rf "$MOUNT_DIR/root/usr/local/bin/Switch to SD2 for Roms.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/usr/local/bin/Switch to main SD for Roms.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Wifi.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Network Info.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Enable Remote Services.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Disable Remote Services.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Change Time.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/NDS Overlays"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Change Ports SDL.sh"
  safe find "$MOUNT_DIR/root/opt/system/Advanced" -name 'Restore*.sh' ! -name 'Restore ArkOS Settings.sh' -exec rm -f {} +
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Screen - Switch to Original Screen Timings.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Reset EmulationStation Controls.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Fix Global Hotkeys.sh"

  echo "== 注入工具 =="
  fatal sudo cp -r "./Jason3_Scripte/wifi-toggle/Wifi-toggle.sh" "$MOUNT_DIR/root/opt/system/Wifi-Toggle.sh"
  fatal sudo cp -r "./Jason3_Scripte/InfoSystem/InfoSystem.sh" "$MOUNT_DIR/root/opt/system/Tools/System Info.sh"
  fatal sudo cp -r "./Jason3_Scripte/GhostLoader/GhostLoader.sh" "$MOUNT_DIR/root/opt/system/Tools/Ghost Loader.sh"
  fatal sudo cp -r "./Jason3_Scripte/Bluetooth-Manager/Bluetooth Manager.sh" "$MOUNT_DIR/root/opt/system/Tools/"
  fatal sudo cp -r "./Jason3_Scripte/Bluetooth-Manager/patch.pak" "$MOUNT_DIR/root/opt/system/Tools/"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/"*.sh
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/Tools/"*.sh
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/opt/system/Advanced/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/Tools/"*.sh
  safe sudo chmod -R 777 "$MOUNT_DIR/root/opt/system/Advanced/"*.sh

  echo "== 设置 ArkOS plymouth 标题 =="
  safe sudo sed -i "/title\=/c\title\=ArkOS4Clone ($UPDATE_DATE)($MODDER)" "$MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth"
fi

safe sudo touch $MOUNT_DIR/boot/"USE_DTB_SELECT_TO_SELECT_DEVICE"
echo "== 注入后镜像 root 分区剩余空间 =="
df -h "$MOUNT_DIR/root" || true
cat $MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth
if (( FAIL_COUNT > 0 )); then
  echo "[ERROR] 注入过程中有 $FAIL_COUNT 个命令失败，镜像可能不完整，构建中止。"
  exit 1
fi
echo "== 完成 =="
