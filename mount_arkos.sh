#!/usr/bin/env bash
set -euo pipefail

# One-key mount/unmount for ArkOS multi-partition images
# Usage:
#   sudo ./mount_arkos.sh mount   /path/to/ArkOS_*.img
#   sudo ./mount_arkos.sh unmount
#
# Mount points will be created under: ./mnt/{boot,root,roms}
# State (loop device) is stored in:   ./.arkos_loop

BASE_MNT="${ARKOS_MNT:-/home/lcdyk/arkos/mnt}"
STATE_FILE="$BASE_MNT/.arkos_loop"
BOOT_MNT="$BASE_MNT/boot"
ROOT_MNT="$BASE_MNT/root"
ROMS_MNT="$BASE_MNT/roms"

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Please run as root (use sudo)." >&2
    exit 1
  fi
}

ensure_tools() {
  for t in losetup mount umount lsblk; do
    command -v "$t" >/dev/null 2>&1 || {
      echo "Missing tool: $t" >&2
      exit 1
    }
  done
}

write_state() {
  echo "$1" > "$STATE_FILE"
}

read_state() {
  [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || true
}

clear_state() {
  rm -f "$STATE_FILE"
}

mk_mount_dirs() {
  mkdir -p "$BOOT_MNT" "$ROOT_MNT" "$ROMS_MNT"
}

is_mounted() {
  mountpoint -q "$1"
}

mount_if_not() {
  local dev="$1" mnt="$2" fstype="${3:-auto}" opts="${4:-}"
  if is_mounted "$mnt"; then
    echo "Already mounted: $mnt"
    return 0
  fi
  if [[ -n "$opts" ]]; then
    mount -t "$fstype" -o "$opts" "$dev" "$mnt"
  else
    mount -t "$fstype" "$dev" "$mnt"
  fi
  echo "Mounted $dev -> $mnt"
}

do_mount() {
  local img="$1"

  # sanity
  [[ -f "$img" ]] || { echo "Image not found: $img" >&2; exit 1; }

  # create loop with partition scan
  local loop
  loop="$(losetup -fP --show "$img")"   # e.g. /dev/loop7
  echo "Loop device: $loop"
  write_state "$loop"

  # wait for kernel to create loopXp{1,2,3}
  sleep 0.5

  # show partitions
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT "$loop"

  # mount points
  mk_mount_dirs

  # Try common layout:
  #  p1 = boot (FAT32), p2 = root (ext4), p3 = roms (exFAT)
  local p1="${loop}p1"
  local p2="${loop}p2"
  local p3="${loop}p3"

  [[ -b "$p1" ]] || { echo "Missing ${p1} (boot)"; }
  [[ -b "$p2" ]] || { echo "Missing ${p2} (root)"; }
  [[ -b "$p3" ]] || { echo "Missing ${p3} (roms)"; }

  # mount with gentle defaults (ro for boot if you prefer safety)
  mount_if_not "$p1" "$BOOT_MNT" vfat "rw,utf8,umask=000"

  # Check if root partition is ext4 or btrfs
  local root_fstype
  root_fstype=$(blkid -o value -s TYPE "$p2")

  if [[ "$root_fstype" == "ext4" ]]; then
    mount_if_not "$p2" "$ROOT_MNT" ext4
  elif [[ "$root_fstype" == "btrfs" ]]; then
    mount_if_not "$p2" "$ROOT_MNT" btrfs
  else
    echo "Unsupported file system on root partition: $root_fstype"
    exit 1
  fi
  
  # exfat utils differ; use 'exfat' fstype and safe options if available
  if grep -qw exfat /proc/filesystems 2>/dev/null; then
    mount_if_not "$p3" "$ROMS_MNT" exfat "rw,uid=0,gid=0,umask=000"
  else
    # fallback: kernel exfat may appear as 'fuseblk' via fuse-exfat, still ok
    mount_if_not "$p3" "$ROMS_MNT"
  fi

  echo
  echo "All set."
  echo "  BOOT -> $BOOT_MNT"
  echo "  ROOT -> $ROOT_MNT"
  echo "  ROMS -> $ROMS_MNT"
}

do_unmount() {
  local loop
  loop="$(read_state)"

  # unmount in reverse order
  for m in "$ROMS_MNT" "$ROOT_MNT" "$BOOT_MNT"; do
    if is_mounted "$m"; then
      umount "$m" || {
        echo "Failed to unmount $m" >&2
        exit 1
      }
      echo "Unmounted $m"
    fi
  done

  # detach loop
  if [[ -n "$loop" && -b "$loop" ]]; then
    losetup -d "$loop" || {
      echo "Failed to detach $loop" >&2
      exit 1
    }
    echo "Detached loop: $loop"
  else
    # try auto-detect any loop that points to our image mounts
    for dev in /dev/loop*; do
      [[ -b "$dev" ]] || continue
      if lsblk -no MOUNTPOINT "$dev" | grep -q "$BASE_MNT" 2>/dev/null; then
        losetup -d "$dev" && echo "Detached loop: $dev"
      fi
    done
  fi

  clear_state
  echo "Done."
}

main() {
  need_root
  ensure_tools

  local cmd="${1:-}"
  case "$cmd" in
    mount)
      [[ $# -ge 2 ]] || { echo "Usage: sudo $0 mount /path/to/image.img"; exit 1; }
      do_mount "$2"
      ;;
    unmount|umount)
      do_unmount
      ;;
    *)
      cat >&2 <<USAGE
Usage:
  sudo $0 mount   /path/to/ArkOS_*.img   # attach, map partitions, mount to ./mnt/{boot,root,roms}
  sudo $0 unmount                        # unmount all and detach loop device

Notes:
  - Requires: losetup, mount, umount, lsblk
  - State file: $STATE_FILE (stores the loop device name)
USAGE
      exit 1
      ;;
  esac
}

main "$@"
