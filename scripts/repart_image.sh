#!/usr/bin/env bash
set -euo pipefail

# ============ 配置 ============
# ARKOS_QUIET=1 时静默（由 build_image.sh --ci 传入）
if [[ "${ARKOS_QUIET:-}" == "1" ]]; then
  RSYNC_PROGRESS="--quiet"
else
  RSYNC_PROGRESS="--info=progress2"
fi
P1_TARGET_MB=256              # p1 (boot) 目标容量: 256MiB (原厂 112MiB)
P2_TARGET_MB=11264            # p2 (root) 目标容量: 11G，设备上不再变动
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# 临时目录优先使用 ARKOS_WORK_DIR，否则使用当前目录
WORK_BASE="${ARKOS_WORK_DIR:-$(pwd)}"
TMP_DIR="${WORK_BASE}/tmp"    # 备份/恢复目录；脚本会创建、用完后删除
# P3 文件系统类型和卷标将自动从原始 p3 检测
# =============================

if [[ $# -lt 1 ]]; then
  echo "用法: $0 <镜像文件路径>"
  exit 1
fi
IMG="$1"
[[ -f "$IMG" ]] || { echo "找不到镜像: $IMG"; exit 1; }

# 运行期资源（挂载点等）
P1_OLD_MNT="$(mktemp -d -t p1_old.XXXXXX)"
P1_NEW_MNT="$(mktemp -d -t p1_new.XXXXXX)"
P3_OLD_MNT="$(mktemp -d -t p3_old.XXXXXX)"
P3_NEW_MNT="$(mktemp -d -t p3_new.XXXXXX)"
LOOP=""

settle() {
  # 等待内核/udev 创建设备节点；在 WSL 等无 udev 环境用 sleep 兜底
  if command -v udevadm >/dev/null 2>&1; then
    sudo udevadm settle || true
  else
    sleep 1
  fi
}

cleanup() {
  set +e
  mountpoint -q "$P1_OLD_MNT" && sudo umount "$P1_OLD_MNT"
  mountpoint -q "$P1_NEW_MNT" && sudo umount "$P1_NEW_MNT"
  mountpoint -q "$P3_OLD_MNT" && sudo umount "$P3_OLD_MNT"
  mountpoint -q "$P3_NEW_MNT" && sudo umount "$P3_NEW_MNT"
  [[ -d "$P1_OLD_MNT" ]] && rmdir "$P1_OLD_MNT" || true
  [[ -d "$P1_NEW_MNT" ]] && rmdir "$P1_NEW_MNT" || true
  [[ -d "$P3_OLD_MNT" ]] && rmdir "$P3_OLD_MNT" || true
  [[ -d "$P3_NEW_MNT" ]] && rmdir "$P3_NEW_MNT" || true
  # 清理 btrfs 临时挂载点
  local btrfs_mnt="${WORK_BASE:-$(pwd)}/btrfs_resize"
  if [[ -d "$btrfs_mnt" ]]; then
    mountpoint -q "$btrfs_mnt" && sudo umount -l "$btrfs_mnt"
    sudo rmdir "$btrfs_mnt" 2>/dev/null
  fi
  # 解绑当前 loop
  if [[ -n "${LOOP:-}" ]] && losetup -a | grep -q "^$LOOP:"; then
    sudo losetup -d "$LOOP" || true
  fi
}
trap cleanup EXIT

# 解除所有已映射到该镜像的 loop（如果存在）
echo "== 解除旧 loop（如果存在） =="
while read -r dev; do
  [[ -n "$dev" ]] && sudo losetup -d "$dev" || true
done < <(losetup -j "$IMG" | cut -d: -f1)

# 映射镜像到 loop（同时启用分区扫描），原子返回唯一设备名
echo "== 映射镜像到 loop（带分区） =="
LOOP="$(sudo losetup --find --show -P "$IMG")"
settle
echo "使用 loop: $LOOP"

# 清理可能残留的挂载点（设备可能已被其他进程挂载）
echo "== 清理残留挂载点 =="
for part in "${LOOP}p1" "${LOOP}p2" "${LOOP}p3"; do
  if [[ -b "$part" ]]; then
    while read -r mnt; do
      [[ -n "$mnt" ]] && sudo umount -l "$mnt" 2>/dev/null || true
    done < <(findmnt -n -o TARGET "$part" 2>/dev/null || true)
  fi
done

# 扇区信息
SECTOR_SIZE="$(sudo blockdev --getss "$LOOP")"  # 常见 512

# 工具函数：检查 p3 是否存在（机器可读模式）
has_p3() {
  sudo parted -sm "$LOOP" unit s print | grep -qE '^3:'
}

# 读取 p1 / p2 / p3 当前大小，计算各自扩容量
PARTED_OUT="$(sudo parted -sm "$LOOP" unit s print)"
P1_START="$(awk -F: '$1=="1"{gsub(/s/,"",$2); print $2}' <<< "$PARTED_OUT")"
P1_END="$(awk -F: '$1=="1"{gsub(/s/,"",$3); print $3}' <<< "$PARTED_OUT")"
[[ -n "${P1_START:-}" && -n "${P1_END:-}" ]] || { echo "未能读取到分区1信息，退出。"; exit 1; }
P1_CUR_MB=$(( (P1_END - P1_START + 1) * SECTOR_SIZE / 1024 / 1024 ))

CUR_START="$(awk -F: '$1=="2"{gsub(/s/,"",$2); print $2}' <<< "$PARTED_OUT")"
CUR_END="$(awk -F: '$1=="2"{gsub(/s/,"",$3); print $3}' <<< "$PARTED_OUT")"
[[ -n "${CUR_END:-}" ]] || { echo "未能读取到分区2信息，退出。"; exit 1; }
P2_CUR_MB=$(( (CUR_END - CUR_START + 1) * SECTOR_SIZE / 1024 / 1024 ))

P3_CUR_MB=0
if has_p3; then
  P3_START="$(awk -F: '$1=="3"{gsub(/s/,"",$2); print $2}' <<< "$PARTED_OUT")"
  P3_END="$(awk -F: '$1=="3"{gsub(/s/,"",$3); print $3}' <<< "$PARTED_OUT")"
  P3_CUR_MB=$(( (P3_END - P3_START + 1) * SECTOR_SIZE / 1024 / 1024 ))
fi

# p1 扩到固定 256MiB；p2 扩到固定 11G；p3 保持原样 (出厂空盘)
# roms/ 打包为 /roms.tar 由首启解包
BOOT_ADD_MB=$(( P1_TARGET_MB > P1_CUR_MB ? P1_TARGET_MB - P1_CUR_MB : 0 ))
P2_DELTA=$(( P2_TARGET_MB > P2_CUR_MB ? P2_TARGET_MB - P2_CUR_MB : 0 ))

echo "当前 p1: ${P1_CUR_MB}MiB, p2: ${P2_CUR_MB}MiB (End: $CUR_END), p3: ${P3_CUR_MB}MiB"
echo "目标: p1 → ${P1_TARGET_MB}MiB (+${BOOT_ADD_MB}), p2 → ${P2_TARGET_MB}MiB (+${P2_DELTA}), p3 保持 ${P3_CUR_MB}MiB"

# p3 备份固定放 $TMP_DIR/p3data（与 p1 备份 $TMP_DIR/bootfs 区分，
# 恢复时按 HAD_P3 标志判断，避免把 boot 备份误恢复进 p3）
HAD_P3=0

# ======= 第一步：备份 p3 到 TMP_DIR/p3data（若存在） =======
if has_p3; then
  HAD_P3=1
  echo "检测到 p3，准备备份到 $TMP_DIR/p3data"
  mkdir -p "$TMP_DIR/p3data"
  P3_DEV="${LOOP}p3"

  # 沿用原厂: 按原类型重建 p3 (原厂镜像为 NTFS)
  ORIG_P3_FS="$(sudo blkid -s TYPE -o value "$P3_DEV" 2>/dev/null || echo 'vfat')"
  ORIG_P3_LABEL="$(sudo blkid -s LABEL -o value "$P3_DEV" 2>/dev/null || echo 'EASYROMS')"
  echo "原 p3 类型: $ORIG_P3_FS, 卷标: $ORIG_P3_LABEL, 新 p3 沿用"

  echo "挂载旧 p3 到 $P3_OLD_MNT（优先只读）"
  if ! sudo mount -o ro "$P3_DEV" "$P3_OLD_MNT"; then
    echo "只读挂载失败，尝试普通挂载"
    sudo mount "$P3_DEV" "$P3_OLD_MNT"
  fi

  echo "备份 p3 -> $TMP_DIR/p3data（rsync -aH --delete，保证目录为“镜像一致”）"
  sudo rsync -aH --delete $RSYNC_PROGRESS "$P3_OLD_MNT"/ "$TMP_DIR/p3data"/

  echo "卸载旧 p3 挂载点"
  sudo umount "$P3_OLD_MNT"
else
  echo "未发现 p3，跳过备份。"
  # 设置默认值（用于新建 p3）
  ORIG_P3_FS="exfat"
  ORIG_P3_LABEL="EASYROMS"
  echo "将使用默认值创建 p3: 文件系统=$ORIG_P3_FS, 卷标=$ORIG_P3_LABEL"
fi

# ======= 第二步：删除 p3 分区（必须清路） =======
echo "== 删除旧的分区3 =="
if sudo parted -s "$LOOP" rm 3 2>/dev/null; then
  echo "已删除 p3（如果原本存在）"
else
  echo "未能删除 p3（可能原本就不存在），继续。"
fi

# 再次校验，若仍存在 p3 则终止
if has_p3; then
  echo "错误：p3 仍存在，无法继续扩容。请检查分区表后重试。"
  sudo parted "$LOOP" unit s print || true
  exit 1
fi

if (( BOOT_ADD_MB > 0 )); then
  # ======= 第三步A：扩容 p1 (boot) =======
  # p1 后面紧挨着 p2，扩 p1 必须把 p2 的原始数据整体右移：
  # 备份 p1 内容 → 删除 p1/p2 分区表项 → 镜像文件内原始搬运 p2 数据 →
  # 重建 256MiB 的 p1 (mkfs 后恢复内容) → 在新起点重建 p2
  # (boot.ini 用 "load mmc 1:1" 按分区号引导，无 UUID 引用，重建 FAT 安全)

  NEW_P1_END=$(( P1_START + P1_TARGET_MB * 1024 * 1024 / SECTOR_SIZE - 1 ))
  NEW_P2_START=$(( NEW_P1_END + 1 ))
  SHIFT_SECTORS=$(( NEW_P2_START - CUR_START ))
  SHIFT_BYTES=$(( SHIFT_SECTORS * SECTOR_SIZE ))
  MOVE_SRC=$(( CUR_START * SECTOR_SIZE ))
  MOVE_LEN=$(( (CUR_END - CUR_START + 1) * SECTOR_SIZE ))

  # 安全断言：新 p2 起点 1MiB 对齐；搬运目的不越过当前文件尾
  (( NEW_P2_START % (1024 * 1024 / SECTOR_SIZE) == 0 )) \
    || { echo "错误：新 p2 起点 ${NEW_P2_START}s 未 1MiB 对齐，退出。"; exit 1; }
  IMG_SIZE_BYTES="$(stat -c %s "$IMG")"
  (( MOVE_SRC + MOVE_LEN + SHIFT_BYTES <= IMG_SIZE_BYTES )) \
    || { echo "错误：p2 搬运目的区域越过镜像尾部，退出。"; exit 1; }

  echo "== 备份 p1 (boot) 内容 -> $TMP_DIR/bootfs =="
  mkdir -p "$TMP_DIR/bootfs"
  ORIG_P1_LABEL="$(sudo blkid -s LABEL -o value "${LOOP}p1" 2>/dev/null || echo 'BOOT')"
  echo "原 p1 卷标: $ORIG_P1_LABEL (重建后沿用)"
  if ! sudo mount -o ro "${LOOP}p1" "$P1_OLD_MNT"; then
    echo "只读挂载失败，尝试普通挂载"
    sudo mount "${LOOP}p1" "$P1_OLD_MNT"
  fi
  sudo rsync -rltD --delete --no-owner --no-group --no-perms --omit-dir-times \
    $RSYNC_PROGRESS "$P1_OLD_MNT"/ "$TMP_DIR/bootfs"/
  sudo umount "$P1_OLD_MNT"

  echo "== 删除旧分区 1/2 (p3 已删；p2 数据仍在镜像文件中) =="
  sudo parted -s "$LOOP" rm 2
  sudo parted -s "$LOOP" rm 1
  sudo partprobe "$LOOP" || true

  echo "== p2 原始数据右移 ${SHIFT_SECTORS} 扇区 (+${BOOT_ADD_MB}MiB), 共 ${P2_CUR_MB}MiB =="
  # 解绑 loop，直接在镜像文件上搬运（避免 loop 缓存与文件写入不一致）
  sudo losetup -d "$LOOP"
  LOOP=""
  # 反向分块搬运（块 < 位移量，从尾部往前搬，源/目的重叠也不会踩未读数据）
  CHUNK=$(( 16 * 1024 * 1024 ))
  remaining=$MOVE_LEN
  src_off=$(( MOVE_SRC + MOVE_LEN ))
  next_report=$(( 1024 * 1024 * 1024 ))
  while (( remaining > 0 )); do
    (( n = remaining < CHUNK ? remaining : CHUNK ))
    src_off=$(( src_off - n ))
    dd if="$IMG" of="$IMG" bs="$CHUNK" conv=notrunc status=none \
      iflag=count_bytes,skip_bytes oflag=seek_bytes \
      skip="$src_off" seek="$(( src_off + SHIFT_BYTES ))" count="$n"
    remaining=$(( remaining - n ))
    if [[ "${ARKOS_QUIET:-}" != "1" ]] && (( MOVE_LEN - remaining >= next_report )); then
      echo "  已搬运 $(( (MOVE_LEN - remaining) / 1024 / 1024 )) / $(( MOVE_LEN / 1024 / 1024 )) MiB"
      next_report=$(( next_report + 1024 * 1024 * 1024 ))
    fi
  done
  sync

  echo "== 扩大镜像 +$(( P2_DELTA + BOOT_ADD_MB ))MiB =="
  truncate -s +"$(( P2_DELTA + BOOT_ADD_MB ))M" "$IMG"

  echo "== 刷新 loop 大小 =="
  LOOP="$(sudo losetup --find --show -P "$IMG")"
  settle
  echo "loop 已刷新: $LOOP"

  echo "== 重建 p1: ${P1_TARGET_MB}MiB FAT32 (${P1_START}s - ${NEW_P1_END}s) =="
  sudo parted -s "$LOOP" unit s "mkpart primary fat32 ${P1_START}s ${NEW_P1_END}s"
  # 分区类型 0x0b 与原厂一致 (parted 默认给 0x0c)
  sudo sfdisk --change-id "$LOOP" 1 b 2>/dev/null || true
  sudo partprobe "$LOOP" || true
  settle
  sudo mkfs.vfat -F 32 -n "$ORIG_P1_LABEL" "${LOOP}p1"
  echo "== 恢复 p1 内容 =="
  sudo mount "${LOOP}p1" "$P1_NEW_MNT"
  sudo rsync -rltD --no-owner --no-group --no-perms --omit-dir-times \
    $RSYNC_PROGRESS "$TMP_DIR/bootfs"/ "$P1_NEW_MNT"/
  sync
  sudo umount "$P1_NEW_MNT"

  echo "== 重建 p2: ${P2_TARGET_MB}MiB (${NEW_P2_START}s 起) =="
  NEW_P2_END=$(( NEW_P2_START + P2_TARGET_MB * 1024 * 1024 / SECTOR_SIZE - 1 ))
  sudo parted -s "$LOOP" unit s "mkpart primary ${NEW_P2_START}s ${NEW_P2_END}s"
  sudo partprobe "$LOOP" || true
  settle
else
  # ======= 第三步B：p1 已达标，仅原地扩 p2 =======
  echo "p1 已达到 ${P1_TARGET_MB}MiB，跳过 boot 扩容"

  echo "== 扩大镜像 +${P2_DELTA}MiB (仅 p2; p3 保持不变) =="
  truncate -s +"${P2_DELTA}"M "$IMG"

  echo "== 刷新 loop 大小 =="
  sudo losetup -d "$LOOP"
  LOOP="$(sudo losetup --find --show -P "$IMG")"
  settle
  echo "loop 已刷新: $LOOP"

  ADD_SECTORS=$(( P2_DELTA * 1024 * 1024 / SECTOR_SIZE ))
  # 重新读取 p2 End（以防 parted/内核刷新导致边界变化）
  CUR_END="$(sudo parted -sm "$LOOP" unit s print | awk -F: '$1=="2"{gsub(/s/,"",$3); print $3}')"
  [[ -n "${CUR_END:-}" ]] || { echo "刷新后未能读取到分区2信息，退出。"; exit 1; }
  NEW_END=$(( CUR_END + ADD_SECTORS ))
  echo "将 p2 结束扇区扩到: $NEW_END"

  echo "== 扩展 p2 到指定扇区（非100%） =="
  if [ "$P2_DELTA" -gt 0 ]; then
    sudo parted -s "$LOOP" unit s "resizepart 2 ${NEW_END}s"
  else
    echo "p2 已达到目标容量，跳过"
  fi
  sudo partprobe "$LOOP" || true
  settle
fi

echo "== 扩展 p2 内文件系统（自动检测 ext4 / f2fs） =="
P2_DEV="${LOOP}p2"
P2_FS="$(blkid -s TYPE -o value "$P2_DEV" || true)"
case "$P2_FS" in
  ext4|"")
    sudo e2fsck -fy "$P2_DEV"
    sudo resize2fs "$P2_DEV"
    ;;
  f2fs)
    sudo fsck.f2fs -f "$P2_DEV" || true
    sudo resize.f2fs "$P2_DEV"
    ;;
  btrfs)
    # 使用工作目录下的固定挂载点，确保干净
    P2_MNT="${WORK_BASE}/btrfs_resize"
    sudo mkdir -p "$P2_MNT"
    # 确保卸载任何现有挂载
    sudo umount -l "$P2_MNT" 2>/dev/null || true
    sudo umount -l "$P2_DEV" 2>/dev/null || true
    # 清除 btrfs 内核设备缓存（关键！）
    echo "清除 btrfs 设备缓存..."
    sudo btrfs device scan --forget 2>/dev/null || true
    # 挂载并扩容
    sudo mount -t btrfs "$P2_DEV" "$P2_MNT"
    sudo btrfs filesystem resize max "$P2_MNT"
    sudo umount "$P2_MNT"
    sudo rmdir "$P2_MNT" 2>/dev/null || true
    ;;
  *)
    echo "警告：未知/不支持的 p2 文件系统类型：$P2_FS"
    echo "请手动扩展 p2 文件系统后再继续。"
    ;;
esac

# ======= 第四步：重建 p3（p2 尾后到盘尾） =======
echo "== 计算新 p3 起始扇区（p2 End + 1） =="
P2_END_NOW="$(sudo parted -sm "$LOOP" unit s print | awk -F: '$1=="2"{gsub(/s/,"",$3); print $3}')"
[[ -n "${P2_END_NOW:-}" ]] || { echo "未能读取最新 p2 End，退出。"; exit 1; }
P3_START=$(( P2_END_NOW + 1 ))
echo "p2 End: $P2_END_NOW"
echo "p3 Start: $P3_START"

echo "== 在尾部重建 p3 =="
sudo parted -s "$LOOP" unit s "mkpart primary ${P3_START}s 100%"
# 分区类型设为 0x07 (exFAT/NTFS): parted 默认给 83(Linux), Windows 会当隐藏分区不显示
sudo sfdisk --change-id "$LOOP" 3 7 2>/dev/null || true
sudo partprobe "$LOOP" || true
settle

echo "== 格式化新的 p3 =="
P3_DEV="${LOOP}p3"
echo "使用文件系统: $ORIG_P3_FS, 卷标: $ORIG_P3_LABEL"
case "$ORIG_P3_FS" in
  vfat|fat32|fat16)
    sudo mkfs.vfat -F 32 -n "$ORIG_P3_LABEL" "$P3_DEV"
    ;;
  ntfs)
    sudo mkfs.ntfs -F -L "$ORIG_P3_LABEL" "$P3_DEV"
    ;;
  exfat)
    sudo mkfs.exfat -n "$ORIG_P3_LABEL" "$P3_DEV"
    ;;
  *)
    echo "警告：未知文件系统类型 $ORIG_P3_FS，使用 exfat 作为默认"
    sudo mkfs.exfat -n "$ORIG_P3_LABEL" "$P3_DEV"
    ;;
esac

# ======= 第五步：恢复数据（镜像一致） =======
if (( HAD_P3 )); then
  echo "== 恢复数据（镜像一致）：$TMP_DIR/p3data -> 新 p3 =="
  sudo mount "$P3_DEV" "$P3_NEW_MNT"
  # FAT32/exFAT 不支持 Unix 权限，使用 --no-perms --no-owner --no-group
  case "$ORIG_P3_FS" in
    vfat|fat32|fat16|exfat)
      sudo rsync -rltD --no-perms --no-owner --no-group --delete $RSYNC_PROGRESS "$TMP_DIR/p3data"/ "$P3_NEW_MNT"/
      ;;
    *)
      sudo rsync -aH --delete $RSYNC_PROGRESS "$TMP_DIR/p3data"/ "$P3_NEW_MNT"/
      ;;
  esac
  sync
  sudo umount "$P3_NEW_MNT"
  echo "恢复完成。"
else
  echo "原镜像没有 p3，跳过恢复。"
fi

# ======= 第六步：可选检查输出 =======
echo "== 最终分区布局（MiB） =="
sudo parted "$LOOP" unit MiB print || true

# ======= 第七步：删除 tmp 并解绑 loop =======
echo "== 删除备份目录 $TMP_DIR =="
sudo rm -rf "$TMP_DIR"

echo "== 解绑 loop 设备 =="
sudo losetup -d "$LOOP" || true
LOOP=""

echo "✅ 完成：【备份p1+p3 → 删p3 → 右移p2数据并重建p1(${P1_TARGET_MB}M) → 重建p2(${P2_TARGET_MB}M) → 重建p3 → 恢复 → 清理tmp → 解绑loop】"
