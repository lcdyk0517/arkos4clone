#!/usr/bin/env bash
set -Eeuo pipefail

# Rockchip RK3326 fusing script for ODROID-GO2
# Supports writing to whole block devices and IMG files.

IDBLOADER="idbloader.img"
UBOOT="uboot.img"
TRUST="trust.img"

# Offsets in 512-byte sectors (RK standard layout)
IDB_SEEK=64        # 32 KiB
UBOOT_SEEK=16384   # 8  MiB
TRUST_SEEK=24576   # 12 MiB

YES=0

usage() {
  cat <<'EOF'
Usage:
  ./sd_fusing.sh <device>        # write to WHOLE device (e.g. /dev/sdb, /dev/mmcblk0)
  ./sd_fusing.sh -i <image.img>  # write to IMG file via loop
Options:
  -y, --yes    non-interactive (assume yes)
  -h, --help   show this help
EOF
}

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    echo "Please run as root (e.g. sudo $0 ...)"
    exit 1
  fi
}

require_bins() {
  local bins=(dd losetup lsblk findmnt sync)
  for b in "${bins[@]}"; do
    command -v "$b" >/dev/null 2>&1 || { echo "Missing required tool: $b"; exit 1; }
  done
  command -v eject >/dev/null 2>&1 || true   # optional
}

check_images() {
  for f in "$IDBLOADER" "$UBOOT" "$TRUST"; do
    [[ -f "$f" ]] || { echo "Missing image: $f"; exit 1; }
  done
  echo "✓ All required images present."
}

is_partition_path() {
  local dev="$1"
  # /dev/sdXn, /dev/mmcblkXpN, /dev/loopXpN
  [[ "$dev" =~ /dev/sd[a-z][0-9]+$ || "$dev" =~ /dev/mmcblk[0-9]+p[0-9]+$ || "$dev" =~ /dev/loop[0-9]+p[0-9]+$ ]]
}

confirm() {
  [[ $YES -eq 1 ]] && return 0
  read -r -p "WARNING: This will destroy ALL data on $1. Continue? [y/N] " ans || true
  case "${ans:-}" in
    y|Y|yes|YES) ;;
    *) echo "Cancelled."; exit 0 ;;
  esac
}

unmount_all_under() {
  local dev="$1"
  # Find all children partitions mounted under this device and unmount them
  mapfile -t mps < <(lsblk -nrpo MOUNTPOINT "$dev" | awk 'NF')
  if ((${#mps[@]})); then
    echo "Unmounting mounted partitions on $dev ..."
    # Reverse order for safe unmount
    for (( i=${#mps[@]}-1; i>=0; i-- )); do
      umount "${mps[$i]}" || { echo "Failed to unmount ${mps[$i]}"; exit 1; }
    done
  fi
}

write_one() {
  local img="$1" dev="$2" seek="$3"
  dd if="$img" of="$dev" bs=512 seek="$seek" conv=fsync,notrunc status=progress
}

fuse_to_device() {
  local dev="$1" kind="${2:-device}"  # kind: device|loop
  echo "Target: $dev ($kind)"

  [[ -b "$dev" ]] || { echo "Error: $dev is not a block device"; exit 1; }
  if is_partition_path "$dev"; then
    echo "Error: $dev looks like a PARTITION. Please pass the WHOLE device (e.g. /dev/sdb, not /dev/sdb1)."
    exit 1
  fi

  confirm "$dev"
  unmount_all_under "$dev"

  echo "Writing bootloader images ..."
  write_one "$IDBLOADER" "$dev" "$IDB_SEEK"
  echo "✓ idbloader written."

  write_one "$UBOOT" "$dev" "$UBOOT_SEEK"
  echo "✓ u-boot written."

  write_one "$TRUST" "$dev" "$TRUST_SEEK"
  echo "✓ trust written."

  sync
  echo "✓ All data synced."

  # Eject only for removable non-loop devices if eject exists
  if [[ "$kind" == "device" ]] && command -v eject >/dev/null 2>&1; then
    # Try best-effort eject; ignore failure
    eject "$dev" || true
    echo "✓ Device ejected (if supported)."
  fi

  echo "✅ Done."
}

ensure_img_min_size() {
  local img="$1"
  local trust_sz
  trust_sz=$(stat -c%s "$TRUST")
  local min_bytes=$(( TRUST_SEEK*512 + trust_sz ))
  local cur_sz
  cur_sz=$(stat -c%s "$img")
  if (( cur_sz < min_bytes )); then
    echo "Expanding image to $(numfmt --to=iec $min_bytes) ..."
    truncate -s "$min_bytes" "$img"
  fi
}

fuse_to_image() {
  local img="$1"
  [[ -f "$img" && -w "$img" ]] || { echo "Error: image file '$img' not found or not writable."; exit 1; }

  ensure_img_min_size "$img"

  echo "Attaching loop device for $img ..."
  # --show prints the loop path; -P creates partition mappings if any
  local loopdev
  loopdev=$(losetup -Pf --show "$img")
  # Ensure cleanup on exit in this scope
  trap 'losetup -d "$loopdev" 2>/dev/null || true' RETURN

  fuse_to_device "$loopdev" "loop"

  echo "Detaching loop device ..."
  losetup -d "$loopdev"
  trap - RETURN
  echo "✅ IMG write done."
}

main() {
  require_root
  require_bins
  check_images

  if [[ $# -eq 0 ]]; then usage; exit 1; fi

  case "$1" in
    -y|--yes) YES=1; shift ;;
  esac

  case "${1:-}" in
    -h|--help) usage ;;
    -i|--image)
      [[ $# -ge 2 ]] || { echo "Error: missing image file."; usage; exit 1; }
      fuse_to_image "$2"
      ;;
    *)
      fuse_to_device "$1" "device"
      ;;
  esac
}

main "$@"
