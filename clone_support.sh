#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# ArkOS4Clone 注入脚本
# 把仓库里的 boot/ rootfs/ roms/ 目录树 rsync 进挂载好的镜像：
#   boot/dArkOS  + boot/ArkOS   -> $MOUNT_DIR/boot
#   rootfs/dArkOS + rootfs/ArkOS -> $MOUNT_DIR/root
#   roms/ (存在时) -> 打包为镜像 /roms.tar，首启解包到扩容后的 p3
# 由 ARKOS_IMAGE_NAME 决定同步策略:
#   *dArkOS*: sync dArkOS，权限 777 / 1000:1000
#   其他    : 先 sync dArkOS 再 sync ArkOS，权限 777 / 1002:1002
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
MOUNT_DIR="${ARKOS_MNT:-/home/lcdyk/arkos/mnt}"
UPDATE_DATE="$(TZ=Asia/Shanghai date +%Y%m%d)"
MODDER="kk&lcdyk"

# safe: 尽力而为的操作，失败保留现场并在结尾判定构建失败
FAIL_COUNT=0
safe() {
  if ! "$@"; then
    echo "[WARN] 失败: $*"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# fatal: 关键操作，失败立即中止构建，避免产出损坏镜像
fatal() {
  if ! "$@"; then
    echo "[ERROR] 致命失败: $*"
    exit 1
  fi
}

echo "== 注入前镜像 root 分区剩余空间 =="
df -h "$MOUNT_DIR/root" || true

# boot 分区 (FAT32) 与 root 分区 (ext4) 的 rsync 参数
# root 用 -p 配合 --chmod=D0777,F0777 让落盘内容即为 777，--chown 指定属主
# -c 按校验和比对: ArkOS/dArkOS 两棵树的 mtime 相同 (git checkout)，
# 且 BMP 等文件"同分辨率=同大小"，用 -t 快速比对会漏掉内容不同的覆盖文件
RSYNC_BOOT_OPTS="-rltcD --no-owner --no-group --no-perms --omit-dir-times"
RSYNC_ROOT_OPTS="-rlptcD --omit-dir-times"

echo "== 解压大型核心 (.so.xz -> .so，已解压则跳过) =="
while IFS= read -r -d '' core_xz; do
  core_so="${core_xz%.xz}"
  if [[ ! -f "$core_so" ]]; then
    echo "解压 $core_xz (解压后删除压缩包)"
    fatal xz -d -T0 "$core_xz"
  fi
done < <(find rootfs -name '*.so.xz' -print0)

sync_boot() {
  fatal sudo rsync $RSYNC_BOOT_OPTS "boot/$1/" "$MOUNT_DIR/boot/"
}

sync_rootfs() {
  # $1: rootfs/ 子目录, $2: 属主 (如 1002:1002)
  fatal sudo rsync $RSYNC_ROOT_OPTS --chown="$2" --chmod=D0777,F0777 "rootfs/$1/" "$MOUNT_DIR/root/"
}

pack_roms_tar() {
  # roms/ 打包为镜像 /roms.tar (存 p2)，首启 expandtoexfat.sh 扩容 p3 后解包
  # 注意: 解包命令是 tar -xf /roms.tar -C /，成员路径必须带 roms/ 前缀
  # 打包在 /tmp 的临时视图里完成: 项目 roms/ 只放增量 (原 roms.tar 没有的东西)，
  # 原厂骨架在打包时临时合入，不落回项目目录
  if [[ ! -d roms ]]; then
    echo "== 跳过 roms 打包 (无 roms/ 目录) =="
    return 0
  fi
  echo "== 打包 roms/ -> 镜像 /roms.tar =="
  # 首启需要的空 roms 目录与 pymo 扫描器 (源在 rootfs 树内)
  local d
  for d in hbmame native32 bbk flash gametank spmp8000 krkr2 pymo; do
    mkdir -p "roms/$d"
  done
  if [[ ! -f roms/pymo/Scan_for_new_games.pymo && -f rootfs/dArkOS/opt/pymo/Scan_for_new_games.pymo ]]; then
    cp -f rootfs/dArkOS/opt/pymo/Scan_for_new_games.pymo roms/pymo/
  fi
  # pymo 主题合入镜像 tempthemes (原厂机制: 首启把 tempthemes 搬进 /roms/themes)
  if [[ -d "$MOUNT_DIR/root/tempthemes/es-theme-nes-box" && ! -d "$MOUNT_DIR/root/tempthemes/es-theme-nes-box/pymo" ]]; then
    echo "== 合并 pymo 主题到镜像 tempthemes =="
    if [[ -d roms/themes/es-theme-nes-box/pymo ]]; then
      fatal sudo cp -r roms/themes/es-theme-nes-box/pymo "$MOUNT_DIR/root/tempthemes/es-theme-nes-box/pymo"
    elif [[ -d rootfs/dArkOS/opt/pymo/pymo ]]; then
      fatal sudo cp -r rootfs/dArkOS/opt/pymo/pymo "$MOUNT_DIR/root/tempthemes/es-theme-nes-box/pymo"
    fi
  fi
  # 组装打包视图: 项目增量 + 原厂骨架 (首启会重格 p3，骨架必须随 tar 进包)
  # 内容放在 stage/roms/ 下，tar 成员即带 roms/ 前缀
  local stage need_mb avail_mb
  stage="$(mktemp -d -t roms_stage.XXXXXXX)"
  need_mb="$(du -sm roms | cut -f1)"
  avail_mb="$(df -Pm /tmp | awk 'NR==2{print $4}')"
  if (( avail_mb < need_mb + 500 )); then
    echo "[ERROR] /tmp 空间不足: 打包需要约 ${need_mb}MB，仅剩 ${avail_mb}MB"
    exit 1
  fi
  mkdir -p "$stage/roms"
  fatal sudo rsync -a roms/ "$stage/roms"/
  if [[ -d "$MOUNT_DIR/roms" ]]; then
    echo "== 合并原厂 roms 骨架 (仅入包，不落项目目录) =="
    fatal sudo rsync -a --exclude 'System Volume Information' --exclude 'EUMONBMP.SYS' --exclude '*.CBM' "$MOUNT_DIR/roms/" "$stage/roms"/
  fi
  # -h 解引用符号链接: 设备 exFAT 不支持链接
  # --owner=0 --group=0: 归档属主归一化为 root (否则会把构建机的 uid 写进包里，
  # 设备端 exFAT 不支持 chown，解压时每个文件都会报 Operation not permitted)
  fatal sudo tar -h --owner=0 --group=0 -cf "$MOUNT_DIR/root/roms.tar" -C "$stage" roms
  fatal sudo chmod 777 "$MOUNT_DIR/root/roms.tar"
  safe sudo rm -rf "$stage"
}

cleanup_stock() {
  # 删除镜像里保留的原厂文件
  safe sudo rm -rf "$MOUNT_DIR/boot/BMPs" "$MOUNT_DIR/boot/ScreenFiles"
  safe sudo rm -rf "$MOUNT_DIR/boot/boot.ini" "$MOUNT_DIR"/boot/*.dtb "$MOUNT_DIR"/boot/*.orig \
    "$MOUNT_DIR"/boot/*.tony "$MOUNT_DIR"/boot/Image "$MOUNT_DIR"/boot/*.bmp \
    "$MOUNT_DIR/boot/WHERE_ARE_MY_ROMS.txt"
  safe sudo rm -f "$MOUNT_DIR/boot/DTB Change Tool.exe"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/DeviceType"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Change LED to Red.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Update.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Wifi.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Network Info.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Enable Remote Services.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Disable Remote Services.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Change Time.sh"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/NDS Overlays"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Advanced/Change Ports SDL.sh"
  safe sudo find "$MOUNT_DIR/root/opt/system/Advanced" -name 'Restore*.sh' ! -name 'Restore ArkOS Settings.sh' -exec rm -f {} +
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Advanced/Screen - Switch to Original Screen Timings.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Advanced/Reset EmulationStation Controls.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Advanced/Fix Global Hotkeys.sh"
  safe sudo rm -f "$MOUNT_DIR/root/etc/emulationstation/es_input.cfg"
  # p3 保持原厂 NTFS 出厂，首启 expandtoexfat.sh 转换为 exFAT 并切换 fstab
  # (fstab.exfat 保留在 boot 分区供首启使用；tempthemes 保留——首启搬进 /roms/themes)
}


# inject_dtb_selector() {
#   echo "== 注入 dtb_selector 与启动标记 =="
#   # linux32 由 build_dtb_selector.sh 在构建开始时编译，必须存在
#   fatal sudo cp -f ./dtb_selector_linux32 "$MOUNT_DIR/boot/"
#   # macos / win32 为桌面端可选工具，有就带上
#   sudo cp -f ./dtb_selector_macos ./dtb_selector_win32.exe "$MOUNT_DIR/boot/" 2>/dev/null || true
#   fatal sudo touch "$MOUNT_DIR/boot/USE_DTB_SELECT_TO_SELECT_DEVICE"
# }

if [[ "$ARKOS_IMAGE_NAME" == *dArkOS* ]]; then
  # ============================================================
  # dArkOS (UID=1000)
  # ============================================================
  echo "=== 检测到 dArkOS 镜像：sync dArkOS，权限 777 / 1000:1000 ==="
  CHOWN_USER="1000:1000"

  echo "== sync boot/dArkOS =="
  sync_boot dArkOS

  echo "== sync rootfs/dArkOS =="
  sync_rootfs dArkOS 1000:1000
  pack_roms_tar

  # inject_dtb_selector

  echo "== 清理 dArkOS 不需要的文件 =="
  cleanup_stock
  safe sudo rm -f "$MOUNT_DIR/root/etc/systemd/system/batt_led.service"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Backup dArkOS Settings"

  echo "== 设置 dArkOS plymouth 标题 =="
  safe sudo sed -i "/title\=/c\title\=dArkOS4Clone ($UPDATE_DATE)($MODDER)" "$MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth"

else
  # ============================================================
  # ArkOS (UID=1002)：先 dArkOS 后 ArkOS 分层覆盖
  # ============================================================
  echo "=== 检测到 ArkOS 镜像：先 sync dArkOS 再 sync ArkOS，权限 777 / 1002:1002 ==="
  CHOWN_USER="1002:1002"

  echo "== sync boot/dArkOS + boot/ArkOS =="
  sync_boot dArkOS
  sync_boot ArkOS

  echo "== sync rootfs/dArkOS + rootfs/ArkOS =="
  sync_rootfs dArkOS 1002:1002
  sync_rootfs ArkOS 1002:1002
  pack_roms_tar

  # inject_dtb_selector

  echo "== 清理 ArkOS 不需要的文件 =="
  cleanup_stock
  safe sudo rm -f "$MOUNT_DIR/root/etc/systemd/system/batt_led.service"
  safe sudo rm -f "$MOUNT_DIR/root/etc/systemd/system/ddtbcheck.service"
  safe sudo rm -rf "$MOUNT_DIR/root/opt/system/Advanced/Read from SD1 and SD2 for Roms"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Advanced/Read from SD1 and SD2 for Roms.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Advanced/Switch to SD2 for Roms.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Advanced/Switch to main SD for Roms.sh"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Advanced/Video Boot/"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Tools/Gamma/"
  safe sudo rm -f "$MOUNT_DIR/root/opt/system/Tools/ES-logo-changer/"
  safe sudo rm -f "$MOUNT_DIR/root/usr/local/bin/Read from SD1 and SD2 for Roms"
  safe sudo rm -f "$MOUNT_DIR/root/usr/local/bin/Switch to SD2 for Roms.sh"
  safe sudo rm -f "$MOUNT_DIR/root/usr/local/bin/Switch to main SD for Roms.sh"

  echo "== 删除logo随机 =="
  safe sudo sed -i '/imageshift\.sh/d' "$MOUNT_DIR/root/var/spool/cron/crontabs/root"
  safe sudo rm -f "$MOUNT_DIR/root/home/ark/.config/imageshift.sh"
  safe sudo chown -R $CHOWN_USER "$MOUNT_DIR/root/lib/systemd/system/mpv.service"
  safe sudo chmod 777 "$MOUNT_DIR/root/lib/systemd/system/mpv.service"

  echo "== 设置 ArkOS plymouth 标题 =="
  safe sudo sed -i "/title\=/c\title\=ArkOS4Clone ($UPDATE_DATE)($MODDER)" "$MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth"
fi

echo "== 注入后镜像 root 分区剩余空间 =="
df -h "$MOUNT_DIR/root" || true
cat "$MOUNT_DIR/root/usr/share/plymouth/themes/text.plymouth"
if (( FAIL_COUNT > 0 )); then
  echo "[ERROR] 注入过程中有 $FAIL_COUNT 个命令失败，镜像可能不完整，构建中止。"
  exit 1
fi
echo "== 完成 =="
