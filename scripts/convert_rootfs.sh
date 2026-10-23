#!/usr/bin/env bash
set -euo pipefail

# Convert the image's root partition (p2) from btrfs to ext4
# Usage: sudo ./convert_rootfs.sh <image file path>
#
# Why ext4 (and not f2fs): neither dArkOS kernel (4.4.189, 5.10) has f2fs, only ext4 and btrfs
# are built in. For a root partition that is mostly read, ext4 also avoids btrfs's costs on a
# slow SD card and a weak CPU: no decompression (a compressed extent is up to 128KiB, so a 4KiB
# random read decompresses the whole extent), no data checksumming, and a smaller metadata tree.
#
# Steps: copy p2 contents to a staging dir in the work dir -> mkfs.ext4 with the same label/UUID
# -> copy back -> rewrite the root line in /etc/fstab and /boot/fstab.exfat (first boot copies the
# latter over the former). Does nothing if p2 is not btrfs.

IMG="${1:-}"
[[ -n "$IMG" && -f "$IMG" ]] || { echo "Usage: $0 <image file path>"; exit 1; }

WORK_BASE="${ARKOS_WORK_DIR:-$(pwd)}"
STAGE="${WORK_BASE}/rootfs_stage"
OLD_MNT="${WORK_BASE}/rootfs_old"
NEW_MNT="${WORK_BASE}/rootfs_new"
BOOT_MNT="${WORK_BASE}/rootfs_boot"

LOOP=""
cleanup() {
  for m in "$BOOT_MNT" "$NEW_MNT" "$OLD_MNT"; do
    mountpoint -q "$m" && umount "$m"
    rmdir "$m" 2>/dev/null || true
  done
  [[ -n "$LOOP" ]] && losetup -d "$LOOP" 2>/dev/null || true
  rm -rf "$STAGE"
}
trap cleanup EXIT

LOOP="$(losetup --find -P --show "$IMG")"
udevadm settle 2>/dev/null || sleep 1
P1="${LOOP}p1"
P2="${LOOP}p2"

FS="$(blkid -s TYPE -o value "$P2" || true)"
if [[ "$FS" != "btrfs" ]]; then
  echo "p2 is ${FS:-unknown}, not btrfs, no conversion needed"
  exit 0
fi

LABEL="$(blkid -s LABEL -o value "$P2" || true)"
UUID="$(blkid -s UUID -o value "$P2" || true)"
echo "== p2 is btrfs (label: ${LABEL:-none}, UUID: ${UUID:-none}), converting to ext4 =="

mkdir -p "$OLD_MNT" "$NEW_MNT" "$BOOT_MNT"
btrfs device scan --forget 2>/dev/null || true
mount -t btrfs -o ro "$P2" "$OLD_MNT"

# rsync -x would skip nested subvolumes (they have their own st_dev), so copy without it;
# list them so a snapshot that would get copied as plain files is visible in the log
SUBVOLS="$(btrfs subvolume list "$OLD_MNT" 2>/dev/null || true)"
if [[ -n "$SUBVOLS" ]]; then
  echo "[WARN] p2 has subvolumes, they are copied as plain directories:"
  echo "$SUBVOLS"
fi

# The staging dir must keep owners, hard links, ACLs and xattrs (e.g. security.capability)
STAGE_FS="$(df --output=fstype "$WORK_BASE" | tail -1)"
case "$STAGE_FS" in
  ext4|xfs|btrfs|f2fs|tmpfs) ;;
  *) echo "[ERROR] Work dir is on $STAGE_FS, which cannot keep Linux owners/xattrs; use an ext4 work dir"; exit 1 ;;
esac

USED_KB="$(du -s --apparent-size -k "$OLD_MNT" | cut -f1)"
AVAIL_KB="$(df -k --output=avail "$WORK_BASE" | tail -1)"
P2_KB=$(( $(blockdev --getsize64 "$P2") / 1024 ))
echo "Uncompressed size: $(( USED_KB / 1024 ))MiB, p2: $(( P2_KB / 1024 ))MiB, free in work dir: $(( AVAIL_KB / 1024 ))MiB"
# ext4 needs room for inode tables and the journal on top of the data
(( USED_KB * 110 / 100 < P2_KB )) || { echo "[ERROR] Uncompressed root does not fit in p2"; exit 1; }
(( USED_KB * 110 / 100 < AVAIL_KB )) || { echo "[ERROR] Not enough free space in the work dir for staging"; exit 1; }

# btrfs.* are btrfs properties exposed as xattrs (e.g. btrfs.compression), ext4 rejects them
RSYNC_OPTS=(-aHAX --numeric-ids --filter='-x btrfs.*')

echo "== Copying p2 -> staging dir =="
rm -rf "$STAGE"
mkdir -p "$STAGE"
rsync "${RSYNC_OPTS[@]}" "$OLD_MNT/" "$STAGE/"
umount "$OLD_MNT"

# mkfs options, chosen for the 4.4 kernel and for reads:
#  ^orphan_file (e2fsprogs >= 1.47 default) needs kernel 5.15+, the image would not mount
#  ^metadata_csum_seed: only useful for changing the UUID later, keep the feature set conservative
#  lazy_itable_init=0/lazy_journal_init=0: initialize inode tables and journal now, so the device
#  does not spend its first boots writing them in the background (ext4lazyinit) while ES loads;
#  the zeroed blocks cost nothing after fstrim + xz
#  -N 262144: the root holds ~100k files; the default (one inode per 16KiB) would reserve ~720k
#  inodes, ~180MiB of inode tables in a partition that is already nearly full
#  -m 1: the default 5% reserve is 600MiB on 12G; ROMs and saves live on p3, not here
MKFS_FEATURES="^metadata_csum_seed"
E2FS_VER="$(mke2fs -V 2>&1 | awk 'NR==1 {print $2}')"
if [[ "$(printf '%s\n1.47\n' "$E2FS_VER" | sort -V | head -1)" == "1.47" ]]; then
  MKFS_FEATURES="$MKFS_FEATURES,^orphan_file"
fi

echo "== Formatting p2 as ext4 (e2fsprogs $E2FS_VER, -O $MKFS_FEATURES) =="
wipefs -a -q "$P2"
mkfs.ext4 -F -q -b 4096 -N 262144 -m 1 \
  ${LABEL:+-L "$LABEL"} ${UUID:+-U "$UUID"} \
  -O "$MKFS_FEATURES" \
  -E lazy_itable_init=0,lazy_journal_init=0 \
  "$P2"

echo "== Copying staging dir -> new p2 =="
mount -t ext4 "$P2" "$NEW_MNT"
rsync "${RSYNC_OPTS[@]}" "$STAGE/" "$NEW_MNT/"
rm -rf "$STAGE"

# Root line: ext4, noatime (reads never cause metadata writes), fsck pass 1.
# Any other btrfs line (e.g. a subvolume mounted on /home) has no ext4 equivalent: fail loudly.
fix_fstab() {
  local f="$1"
  [[ -f "$f" ]] || { echo "  $f not found, skipping"; return 0; }
  if awk '$1 !~ /^#/ && $2 != "/" && $3 == "btrfs"' "$f" | grep -q .; then
    echo "[ERROR] $f has btrfs mounts other than /:"
    awk '$1 !~ /^#/ && $2 != "/" && $3 == "btrfs"' "$f"
    exit 1
  fi
  awk 'BEGIN {OFS="\t"} $1 !~ /^#/ && $2 == "/" {$3 = "ext4"; $4 = "defaults,noatime"; $5 = ($5 == "" ? 0 : $5); $6 = 1} {print}' \
    "$f" > "$f.new"
  cat "$f.new" > "$f"
  rm -f "$f.new"
  echo "  $f: $(awk '$1 !~ /^#/ && $2 == "/"' "$f")"
}

# The initramfs runs "fsck -t <type>" on the root at every boot, but it was built while the root
# was btrfs and only carries fsck.btrfs. Without fsck.ext4, fsck exits 8 and the initramfs prints
# "File system check failed" and sleeps 5 seconds on every boot. Rebuilding it needs an arm64
# chroot, so instead append a second cpio with e2fsck and its libraries (the kernel unpacks
# concatenated archives in order) and rewrite the uImage header.
add_fsck_ext4_to_initrd() {
  local initrd="$BOOT_MNT/uInitrd"
  [[ -f "$initrd" ]] || { echo "  $initrd not found, skipping"; return 0; }
  local add="${WORK_BASE}/initrd_add"
  local libdir=usr/lib/aarch64-linux-gnu
  rm -rf "$add" "$add.cpio.gz"
  mkdir -p "$add/usr/sbin" "$add/$libdir"
  cp -L "$NEW_MNT/usr/sbin/e2fsck" "$add/usr/sbin/e2fsck"
  ln -s e2fsck "$add/usr/sbin/fsck.ext4"
  # libblkid and libuuid are already in the initramfs (util-linux)
  for lib in libext2fs.so.2 libcom_err.so.2 libe2p.so.2; do
    cp -L "$NEW_MNT/$libdir/$lib" "$add/$libdir/$lib"
  done
  # Files only: the directories already exist in the initramfs and a directory entry would reset
  # their mode. gzip, not zstd: the 4.4 kernel cannot unpack a zstd initramfs
  (cd "$add" && find . ! -type d | LC_ALL=C sort | cpio -o -H newc -R 0:0 --quiet) | gzip -9n > "$add.cpio.gz"
  rm -rf "$add"

  # Legacy uImage header: 64 bytes, big endian; size at 12, data CRC at 24, header CRC at 4.
  # boot.ini loads the initrd at 0x01100000 and the dtb at 0x01f00000, so it must stay under 14MiB.
  python3 -I - "$initrd" "$add.cpio.gz" <<'PY'
import struct, sys, zlib
path, extra = sys.argv[1], sys.argv[2]
d = open(path, "rb").read()
hdr = bytearray(d[:64])
magic, size = struct.unpack_from(">I", hdr, 0)[0], struct.unpack_from(">I", hdr, 12)[0]
img_type, comp = hdr[30], hdr[31]
if magic != 0x27051956 or img_type != 3 or comp != 0:
    sys.exit("uInitrd is not an uncompressed legacy ramdisk uImage")
payload = d[64:64 + size]
payload += b"\0" * (-len(payload) % 4) + open(extra, "rb").read()
if 64 + len(payload) > 0x01f00000 - 0x01100000:
    sys.exit("new uInitrd would overlap the dtb load address")
struct.pack_into(">I", hdr, 12, len(payload))
struct.pack_into(">I", hdr, 24, zlib.crc32(payload))
struct.pack_into(">I", hdr, 4, 0)
struct.pack_into(">I", hdr, 4, zlib.crc32(bytes(hdr)))
open(path + ".new", "wb").write(bytes(hdr) + payload)
print(f"  uInitrd: {len(d)} -> {64 + len(payload)} bytes")
PY
  mv "$initrd.new" "$initrd"
  rm -f "$add.cpio.gz"
}

echo "== Updating fstab root entries =="
fix_fstab "$NEW_MNT/etc/fstab"
mount "$P1" "$BOOT_MNT"
fix_fstab "$BOOT_MNT/fstab.exfat"
echo "== Adding fsck.ext4 to the initramfs =="
add_fsck_ext4_to_initrd
umount "$BOOT_MNT"

umount "$NEW_MNT"
e2fsck -fy "$P2" > /dev/null || (( $? <= 1 )) || { echo "[ERROR] e2fsck failed on new p2"; exit 1; }
echo "== p2 converted to ext4 =="
