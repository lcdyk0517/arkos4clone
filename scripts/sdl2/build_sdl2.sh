#!/usr/bin/env bash
# Cross-build the SDL2 2.32.10 libraries that clone.sh installs from
# home/ark/.quirks/rotate/sdl2/{64,32}: four variants (norotate, rotate90,
# rotate180, rotate270) for arm64 and armhf, with Vulkan enabled.
#
# usage: build_sdl2.sh --sysroot DIR [--work DIR] [--install] [--jobs N]
#   --sysroot  device sysroot made by fetch_sysroot.sh
#   --work     build directory (default: ./sdl2-build)
#   --install  copy the results into rootfs/dArkOS/home/ark/.quirks/rotate/sdl2
# Environment: CC64/STRIP64 (default aarch64-linux-gnu-gcc/-strip),
#              CC32/STRIP32 (default arm-linux-gnueabihf-gcc/-strip)
set -euo pipefail

# rk3326_core_builds scripts/sdl2.sh: SDL 2.32.10 and its fixups
SDL_URL=https://github.com/libsdl-org/SDL
SDL_COMMIT=5d249570393f7a37e037abf22cd6012a4cc56a71
GAMECONTROLLER_COMMIT=528b71284f491bcb6ecfd4ab7e00d37b296bd621
REVERT_COMMIT=e5024fae3decb724e397d3c9dbcb744d8c79aac1
EXT=3200.10
VARIANTS="norotate rotate270 rotate180 rotate90"

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
patches="$here/patches"
sysroot= work="$PWD/sdl2-build" install=0 jobs="$(nproc)"
while [ $# -gt 0 ]; do
	case "$1" in
	--sysroot) sysroot="$(realpath "$2")"; shift 2 ;;
	--work) work="$2"; shift 2 ;;
	--install) install=1; shift ;;
	--jobs) jobs="$2"; shift 2 ;;
	*) sed -n '2,13p' "$0" >&2; exit 2 ;;
	esac
done
[ -n "$sysroot" ] && [ -d "$sysroot/usr/lib/aarch64-linux-gnu" ] ||
	{ echo "--sysroot must point to a fetch_sysroot.sh sysroot" >&2; exit 2; }
export CC64="${CC64:-aarch64-linux-gnu-gcc}" STRIP64="${STRIP64:-aarch64-linux-gnu-strip}"
export CC32="${CC32:-arm-linux-gnueabihf-gcc}" STRIP32="${STRIP32:-arm-linux-gnueabihf-strip}"
for t in "$CC64" "$STRIP64" "$CC32" "$STRIP32" git cmake ninja patch; do
	command -v "$t" >/dev/null || { echo "missing tool: $t" >&2; exit 1; }
done
mkdir -p "$work"
work="$(realpath "$work")"

apply() { patch -Np1 --no-backup-if-mismatch -s -d "$1" < "$patches/$2"; }

# Base tree: what sdl2.sh builds as the unrotated library
rm -rf "$work/SDL" "$work/src" "$work/out"
git clone -q "$SDL_URL" "$work/SDL"
git -C "$work/SDL" checkout -q "$SDL_COMMIT"
apply "$work/SDL" sdl2-patch-0001-egl.patch
apply "$work/SDL" sdl2-patch-0002-disable-mouse-cursor.patch
git -C "$work/SDL" checkout -q "$GAMECONTROLLER_COMMIT" -- src/joystick/SDL_gamecontroller.c
git -C "$work/SDL" revert -n "$REVERT_COMMIT" >/dev/null
# dlopen GBM by its soname instead of the libmali file it resolves to
apply "$work/SDL" sdl2-patch-0009-gbm-soname.patch

# Variants: 270 is the odroidgoa rotation patch, 180 builds on it, 90 on 180
mkdir -p "$work/src"
for v in $VARIANTS; do
	mkdir -p "$work/src/$v"
	(cd "$work/SDL" && git ls-files -co --exclude-standard -z | xargs -0 cp -a --parents -t "$work/src/$v")
done
for v in rotate270 rotate180 rotate90; do
	apply "$work/src/$v" sdl2-patch-0004-odroidgoa-kmsdrm.patch
	apply "$work/src/$v" sdl2-patch-0005-odroidgoa-rotate-cursor.patch
done
apply "$work/src/rotate180" sdl2-patch-0007-rotate180.patch
apply "$work/src/rotate90" sdl2-patch-0007-rotate180.patch
apply "$work/src/rotate90" sdl2-patch-0008-rotate90.patch

build_one() {
	local v=$1 bits=$2 triplet proc cc strip b
	if [ "$bits" = 64 ]; then
		triplet=aarch64-linux-gnu proc=aarch64 cc=$CC64 strip=$STRIP64
	else
		triplet=arm-linux-gnueabihf proc=arm cc=$CC32 strip=$STRIP32
	fi
	b="$WORK/src/$v/build$bits"
	mkdir -p "$b"
	# Options of sdl2.sh's 64-bit cmake build, plus SDL_VULKAN=ON; sdl2.sh
	# builds 32-bit with autotools, here both use cmake. libsamplerate is
	# off: the shipped builds never had it.
	PKG_CONFIG_SYSROOT_DIR="$SYSROOT" \
	PKG_CONFIG_LIBDIR="$SYSROOT/usr/lib/$triplet/pkgconfig:$SYSROOT/usr/share/pkgconfig" \
	cmake -S "$WORK/src/$v" -B "$b" -G Ninja \
		-DCMAKE_SYSTEM_NAME=Linux -DCMAKE_SYSTEM_PROCESSOR=$proc \
		-DCMAKE_C_COMPILER="$cc" -DCMAKE_SYSROOT="$SYSROOT" \
		-DCMAKE_FIND_ROOT_PATH="$SYSROOT" \
		-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		-DCMAKE_C_FLAGS="-I$SYSROOT/usr/local/include -Wno-error=int-conversion" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr/lib/$triplet -DCMAKE_INSTALL_LIBDIR=/usr/lib/$triplet \
		-DSDL_STATIC=OFF -DSDL_TEST=OFF -DSDL_LIBC=ON -DSDL_GCC_ATOMICS=ON -DSDL_ALTIVEC=OFF \
		-DSDL_OSS=OFF -DSDL_ALSA=ON -DSDL_ALSA_SHARED=ON -DSDL_JACK=OFF -DSDL_JACK_SHARED=OFF \
		-DSDL_ESD=OFF -DSDL_ESD_SHARED=OFF -DSDL_ARTS=OFF -DSDL_ARTS_SHARED=OFF -DSDL_NAS=OFF \
		-DSDL_NAS_SHARED=OFF -DSDL_LIBSAMPLERATE=OFF -DSDL_SNDIO=OFF -DSDL_DISKAUDIO=OFF \
		-DSDL_DUMMYAUDIO=OFF -DSDL_WAYLAND=OFF -DSDL_WAYLAND_QT_TOUCH=OFF \
		-DSDL_WAYLAND_SHARED=OFF -DSDL_COCOA=OFF -DSDL_DIRECTFB=OFF -DSDL_VIVANTE=OFF \
		-DSDL_DIRECTFB_SHARED=OFF -DSDL_FUSIONSOUND=OFF -DSDL_FUSIONSOUND_SHARED=OFF \
		-DSDL_DUMMYVIDEO=OFF -DSDL_PTHREADS=ON -DSDL_PTHREADS_SEM=ON -DSDL_DIRECTX=OFF \
		-DSDL_CLOCK_GETTIME=OFF -DSDL_RPATH=OFF -DSDL_RENDER_D3D=OFF -DSDL_X11=OFF \
		-DSDL_OPENGLES=ON -DSDL_VULKAN=ON -DSDL_KMSDRM=ON -DSDL_PULSEAUDIO=ON \
		> "$b/cmake.log" 2>&1 || { echo "cmake failed: $b/cmake.log" >&2; return 1; }
	ninja -C "$b" -j4 > "$b/build.log" 2>&1 || { echo "build failed: $b/build.log" >&2; return 1; }
	"$strip" -o "$WORK/out/$bits/libSDL2-2.0.so.0.$EXT.$v" "$b/libSDL2-2.0.so.0.$EXT"
	echo "built $bits/libSDL2-2.0.so.0.$EXT.$v"
}
export -f build_one
export WORK="$work" SYSROOT="$sysroot" EXT

mkdir -p "$work/out/64" "$work/out/32"
for bits in 64 32; do for v in $VARIANTS; do echo "$v $bits"; done; done |
	xargs -P "$(( (jobs + 3) / 4 ))" -L 1 bash -c 'build_one "$@"' _

(cd "$work/out" && sha256sum */*) | tee "$work/out/SHA256SUMS"
if [ "$install" = 1 ]; then
	dest="$repo/rootfs/dArkOS/home/ark/.quirks/rotate/sdl2"
	for bits in 64 32; do
		install -m 755 "$work/out/$bits"/libSDL2-2.0.so.0.$EXT.* "$dest/$bits/"
	done
	echo "installed into $dest"
fi
