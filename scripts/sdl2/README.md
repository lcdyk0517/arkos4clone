# SDL2 for ArkOS4Clone

`clone.sh` installs one of the libraries in
`rootfs/dArkOS/home/ark/.quirks/rotate/sdl2/{64,32}/` as the system SDL2,
depending on the console's screen rotation. These scripts rebuild all eight
(norotate, rotate90, rotate180, rotate270 for arm64 and armhf) by
cross-compiling against a sysroot taken from a running device.

The recipe is christianhaitian/rk3326_core_builds `scripts/sdl2.sh` (as of
0b6a783194ab3905a4fc21eb87112cada3510c0b): SDL 2.32.10
(5d249570393f7a37e037abf22cd6012a4cc56a71), the older
`SDL_gamecontroller.c` from 528b71284f49, and e5024fae3dec reverted.
Differences from that recipe:

- Vulkan is enabled (`SDL_VULKAN=ON`), so `SDL_WINDOW_VULKAN` and
  `SDL_Vulkan_CreateSurface()` work on KMSDRM through the Mali driver's
  `VK_KHR_display`.
- armhf is built with CMake like arm64 (the recipe uses autotools for it).
- libsamplerate is off; the previously shipped builds did not have it.
- GBM is loaded as `libgbm.so.1` (patch 0009) instead of the libmali file
  name the build host's `libgbm.so` happens to resolve to.

## Patches

| Patch | Source | Used by |
| --- | --- | --- |
| sdl2-patch-0001-egl | rk3326_core_builds | all |
| sdl2-patch-0002-disable-mouse-cursor | rk3326_core_builds | all |
| sdl2-patch-0004-odroidgoa-kmsdrm | rk3326_core_builds (RGA rotation, 270°) | rotate* |
| sdl2-patch-0005-odroidgoa-rotate-cursor | rk3326_core_builds | rotate* |
| sdl2-patch-0007-rotate180 | this repository, 9f2a0e2 | rotate180, rotate90 |
| sdl2-patch-0008-rotate90 | this repository, 6c50931 | rotate90 |
| sdl2-patch-0009-gbm-soname | ArkOS4Clone | all |

## Build

Requirements: git, cmake, ninja, patch, `aarch64-linux-gnu-gcc` and an
armhf cross compiler. On Debian:
`sudo apt install gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf cmake ninja-build`.
Without root, `apt-get download gcc-14-arm-linux-gnueabihf
cpp-14-arm-linux-gnueabihf gcc-14-arm-linux-gnueabihf-base
libgcc-14-dev-armhf-cross libgcc-s1-armhf-cross binutils-arm-linux-gnueabihf`
and `dpkg -x` them into a directory works too; put its `usr/bin` in `PATH`,
its `usr/lib/x86_64-linux-gnu` in `LD_LIBRARY_PATH`, and set
`CC32=arm-linux-gnueabihf-gcc-14`.

```
SSH="sshpass -p ark ssh" scripts/sdl2/fetch_sysroot.sh ark@<device-ip> /path/to/sysroot
scripts/sdl2/build_sdl2.sh --sysroot /path/to/sysroot --install
```

`--install` copies the results into `rootfs/dArkOS/home/ark/.quirks/rotate/sdl2`;
without it they stay in `<work>/out` with `SHA256SUMS`. The build is
deterministic for a given sysroot, compiler and `--work` directory (SDL
records source paths in the library).
