#!/bin/bash
set -e

TARGET=dtb_selector
GO=go
FLAGS=(-ldflags="-s -w")
MODULE_DIR=dtbtools
ROOT_DIR=$(pwd)

platform_win32() {
  EXE="boot/dArkOS/${TARGET}_win32.exe"
  echo "Building: Windows 32-bit"
  (cd "$MODULE_DIR" && GOOS=windows GOARCH=386 $GO build "$FLAGS" -o "$ROOT_DIR/$EXE" .)
  echo "Generated: $EXE"
}

platform_win64() {
  EXE="boot/dArkOS/${TARGET}_win64.exe"
  echo "Building: Windows 64-bit"
  (cd "$MODULE_DIR" && GOOS=windows GOARCH=amd64 $GO build "$FLAGS" -o "$ROOT_DIR/$EXE" .)
  echo "Generated: $EXE"
}

platform_macos_intel() {
  EXE="boot/dArkOS/${TARGET}_macos_intel"
  echo "Building: macOS Intel"
  (cd "$MODULE_DIR" && GOOS=darwin GOARCH=amd64 $GO build "$FLAGS" -o "$ROOT_DIR/$EXE" .)
  echo "Generated: $EXE"
}

platform_macos_apple_silicon() {
  EXE="boot/dArkOS/${TARGET}_macos_apple"
  echo "Building: macOS Apple Silicon"
  (cd "$MODULE_DIR" && GOOS=darwin GOARCH=arm64 $GO build "$FLAGS" -o "$ROOT_DIR/$EXE" .)
  echo "Generated: $EXE"
}

platform_macos() {
  LIPO=$(go env GOPATH)/bin/lipo
  if [[ ! -x "$LIPO" ]]
  then
    echo "Installing: lipo"
    $GO install github.com/konoui/lipo@latest
  fi

  EXE="boot/dArkOS/${TARGET}_macos"
  echo "Building: macOS Universal"

  (cd "$MODULE_DIR" && GOOS=darwin GOARCH=amd64 $GO build "$FLAGS" -o "$ROOT_DIR/${EXE}_amd64" .)
  (cd "$MODULE_DIR" && GOOS=darwin GOARCH=arm64 $GO build "$FLAGS" -o "$ROOT_DIR/${EXE}_arm64" .)
  "$LIPO" -output "$ROOT_DIR/$EXE" -create "$ROOT_DIR/${EXE}_arm64" "$ROOT_DIR/${EXE}_amd64"

  rm -f "$ROOT_DIR/${EXE}_amd64" "$ROOT_DIR/${EXE}_arm64"

  echo "Generated: $EXE"
}

platform_linux32() {
  EXE="boot/dArkOS/${TARGET}_linux32"
  echo "Building: Linux 32-Bit"
  (cd "$MODULE_DIR" && GOOS=linux GOARCH=386 $GO build "$FLAGS" -o "$ROOT_DIR/$EXE" .)
  echo "Generated: $EXE"
}

platform_linux64() {
  EXE="boot/dArkOS/${TARGET}_linux64"
  echo "Building: Linux 64-Bit"
  (cd "$MODULE_DIR" && GOOS=linux GOARCH=amd64 $GO build "$FLAGS" -o "$ROOT_DIR/$EXE" .)
  echo "Generated: $EXE"
}

if [[ "$1" == "--clean" ]]
then
  rm -rf "boot/dArkOS/${TARGET}_win32.exe"   \
         "boot/dArkOS/${TARGET}_win64.exe"   \
         "boot/dArkOS/${TARGET}_macos_intel" \
         "boot/dArkOS/${TARGET}_macos_apple" \
         "boot/dArkOS/${TARGET}_macos" \
         "boot/dArkOS/${TARGET}_linux32" \
         "boot/dArkOS/${TARGET}_linux64"
  exit
fi

PLATFORMS=(
  platform_win32
  platform_macos
  platform_linux32
)

for platform in ${PLATFORMS[@]}
do
  $platform;
  echo;
done
