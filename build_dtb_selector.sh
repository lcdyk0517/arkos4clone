#!/bin/bash
set -e

TARGET=dtb_selector
GO=go
FLAGS=(-ldflags="-s -w")
SRC=dtb_selector.go

# available platforms
# - platform_win32
# - platform_win64
# - platform_macos_intel
# - platform_macos_apple_silicon
# - platform_linux64
PLATFORMS=(
    platform_win32
    platform_macos_intel
    platform_macos_apple_silicon
)

platform_win32() {
    EXE="${TARGET}_win32.exe"
	echo "Building: Windows 32-bit"
	GOOS=windows GOARCH=386 $GO build "$FLAGS" -o "$EXE" "$SRC"
	echo "Generated: $EXE"
}

platform_win64() {
    EXE="${TARGET}_win64.exe"
	echo "Building: Windows 64-bit"
	GOOS=windows GOARCH=amd64 $GO build "$FLAGS" -o "$EXE" "$SRC"
	echo "Generated: $EXE"
}

platform_macos_intel() {
    EXE="${TARGET}_macos_intel"
	echo "Building: macOS Intel"
	GOOS=darwin GOARCH=amd64 $GO build "$FLAGS" -o "$EXE" "$SRC"
	echo "Generated: $EXE"
}

platform_macos_apple_silicon() {
    EXE="${TARGET}_macos_apple"
	echo "Building: macOS Apple Silicon"
	GOOS=darwin GOARCH=arm64 $GO build "$FLAGS" -o "$EXE" "$SRC"
	echo "Generated: $EXE"
}

platform_linux64() {
    EXE="${TARGET}_linux"
	echo "Building: Linux 64-Bit"
	GOOS=linux GOARCH=amd64 $GO build "$FLAGS" -o "$EXE" "$SRC"
	echo "Generated: $EXE"
}

if [[ "$1" == "--clean" ]]
then
    rm -rf "${TARGET}_win32.exe"   \
           "${TARGET}_win64.exe"   \
           "${TARGET}_macos_intel" \
           "${TARGET}_macos_apple" \
           "${TARGET}_linux"
    exit
fi

for platform in ${PLATFORMS[@]}
do
    $platform;
    echo;
done
