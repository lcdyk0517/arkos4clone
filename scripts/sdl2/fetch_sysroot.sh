#!/usr/bin/env bash
# Copy the headers and libraries that the SDL2 build needs from a running
# ArkOS4Clone device into a local sysroot (both arm64 and armhf).
#
# usage: fetch_sysroot.sh <user@host> <sysroot dir>
# SSH must work non-interactively (key, or sshpass -p ark in SSH="...").
set -euo pipefail

[ $# -eq 2 ] || { echo "usage: $0 <user@host> <sysroot dir>" >&2; exit 2; }
target=$1
sysroot=$2
ssh_cmd=${SSH:-ssh}

mkdir -p "$sysroot"
# Large libraries the build never links against are left out (~600 MB is
# copied instead of ~1.7 GB). Static archives are skipped except small ones
# such as libc_nonshared.a, which the linker needs.
$ssh_cmd "$target" 'cd / && {
	printf "%s\n" usr/include usr/local/include usr/lib/linux usr/lib/ld-linux-*
	find usr/lib/aarch64-linux-gnu usr/lib/arm-linux-gnueabihf -mindepth 1 -maxdepth 1 \
		! -name "libLLVM*" ! -name "librustc*" ! -name "libclang*" ! -name samba \
		! -name "libicudata*" ! -name vlc ! -name "perl*" ! -name "libz3*" \
		! -name "espeak*" ! -name gconv ! -name "libcodec2*" ! -name "libvulkan_*" \
		! -name "libav*" ! -name "libasan*" ! -name "libx26*" ! -name "libgallium*" \
		! -name dri ! -name "gstreamer*" ! -name "python3*" ! -name "qt5" ! -name "qt6" \
		! -name "libQt*" ! -name "libtsan*" ! -name "libhwasan*" ! -name "liblsan*" \
		! -name "libubsan*" ! -name "libgo*" ! -name "libgfortran*" ! -name "*.so.*.p" \
		! \( -name "*.a" -size +4M \)
	} > /tmp/sysroot.list && tar -cf - -T /tmp/sysroot.list 2>/dev/null; rm -f /tmp/sysroot.list' |
	tar -xf - -C "$sysroot"
ln -sfn usr/lib "$sysroot/lib"
echo "sysroot: $sysroot ($(du -sh "$sysroot" | cut -f1))"
