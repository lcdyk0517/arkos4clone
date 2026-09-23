#!/bin/bash
set -euo pipefail

TARGET=dtb_selector
GO="${GO:-go}"
# 注意: FLAGS 里不要用 =，用空格
FLAGS=(-ldflags "-s -w")

# --- 定位脚本目录和项目根目录 ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "$SCRIPT_DIR/dtbtools" && -d "$SCRIPT_DIR/boot" ]]; then
  ROOT_DIR="$SCRIPT_DIR"
elif [[ -d "$SCRIPT_DIR/../dtbtools" && -d "$SCRIPT_DIR/../boot" ]]; then
  ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
else
  echo "[ERROR] 无法定位项目根目录（需要同时存在 dtbtools/ 和 boot/）" >&2
  exit 1
fi

MODULE_DIR="$ROOT_DIR/dtbtools"
OUT_DIR="$ROOT_DIR/boot/dArkOS"

echo "ROOT_DIR   = $ROOT_DIR"
echo "MODULE_DIR = $MODULE_DIR"
echo "OUT_DIR    = $OUT_DIR"
echo

# --- 平台构建函数 ---
# 所有 EXE 只用相对 OUT_DIR 的文件名
build_win32() {
  local exe="${TARGET}_win32.exe"
  echo "Building: Windows 32-bit"
  (cd "$MODULE_DIR" && GOOS=windows GOARCH=386 "$GO" build "${FLAGS[@]}" -o "$OUT_DIR/$exe" .)
  echo "Generated: boot/dArkOS/$exe"
}

build_win64() {
  local exe="${TARGET}_win64.exe"
  echo "Building: Windows 64-bit"
  (cd "$MODULE_DIR" && GOOS=windows GOARCH=amd64 "$GO" build "${FLAGS[@]}" -o "$OUT_DIR/$exe" .)
  echo "Generated: boot/dArkOS/$exe"
}

build_macos_intel() {
  local exe="${TARGET}_macos_intel"
  echo "Building: macOS Intel"
  (cd "$MODULE_DIR" && GOOS=darwin GOARCH=amd64 "$GO" build "${FLAGS[@]}" -o "$OUT_DIR/$exe" .)
  echo "Generated: boot/dArkOS/$exe"
}

build_macos_apple_silicon() {
  local exe="${TARGET}_macos_apple"
  echo "Building: macOS Apple Silicon"
  (cd "$MODULE_DIR" && GOOS=darwin GOARCH=arm64 "$GO" build "${FLAGS[@]}" -o "$OUT_DIR/$exe" .)
  echo "Generated: boot/dArkOS/$exe"
}

build_macos() {
  local lipo
  lipo="$(go env GOPATH)/bin/lipo"
  if [[ ! -x "$lipo" ]]; then
    echo "Installing: lipo"
    "$GO" install github.com/konoui/lipo@latest
    lipo="$(go env GOPATH)/bin/lipo"
  fi

  local exe="${TARGET}_macos"
  echo "Building: macOS Universal"

  (cd "$MODULE_DIR" && GOOS=darwin GOARCH=amd64 "$GO" build "${FLAGS[@]}" -o "$OUT_DIR/${exe}_amd64" .)
  (cd "$MODULE_DIR" && GOOS=darwin GOARCH=arm64 "$GO" build "${FLAGS[@]}" -o "$OUT_DIR/${exe}_arm64" .)

  "$lipo" -output "$OUT_DIR/$exe" -create "$OUT_DIR/${exe}_arm64" "$OUT_DIR/${exe}_amd64"
  rm -f "$OUT_DIR/${exe}_amd64" "$OUT_DIR/${exe}_arm64"

  echo "Generated: boot/dArkOS/$exe"
}

build_linux32() {
  local exe="${TARGET}_linux32"
  echo "Building: Linux 32-Bit"
  (cd "$MODULE_DIR" && GOOS=linux GOARCH=386 "$GO" build "${FLAGS[@]}" -o "$OUT_DIR/$exe" .)
  echo "Generated: boot/dArkOS/$exe"
}

build_linux64() {
  local exe="${TARGET}_linux64"
  echo "Building: Linux 64-Bit"
  (cd "$MODULE_DIR" && GOOS=linux GOARCH=amd64 "$GO" build "${FLAGS[@]}" -o "$OUT_DIR/$exe" .)
  echo "Generated: boot/dArkOS/$exe"
}

build_linux_arm64() {
  local exe="${TARGET}_linuxarm64"
  echo "Building: Linux ARM64"
  (cd "$MODULE_DIR" && GOOS=linux GOARCH=arm64 "$GO" build "${FLAGS[@]}" -o "$OUT_DIR/$exe" .)
  echo "Generated: boot/dArkOS/$exe"
}

build_linux_arm() {
  local exe="${TARGET}_linuxarm"
  echo "Building: Linux ARM 32-Bit"
  (cd "$MODULE_DIR" && GOOS=linux GOARCH=arm GOARM=7 "$GO" build "${FLAGS[@]}" -o "$OUT_DIR/$exe" .)
  echo "Generated: boot/dArkOS/$exe"
}

# --- --clean ---
clean_all() {
  echo "Cleaning outputs in $OUT_DIR"
  rm -f \
    "$OUT_DIR/${TARGET}_win32.exe" \
    "$OUT_DIR/${TARGET}_win64.exe" \
    "$OUT_DIR/${TARGET}_macos_intel" \
    "$OUT_DIR/${TARGET}_macos_apple" \
    "$OUT_DIR/${TARGET}_macos" \
    "$OUT_DIR/${TARGET}_linux32" \
    "$OUT_DIR/${TARGET}_linux64" \
    "$OUT_DIR/${TARGET}_linuxarm64" \
    "$OUT_DIR/${TARGET}_linuxarm"
}

# --- --help ---
usage() {
  cat <<EOF
Usage: $(basename "$0") [--clean] [--all] [--help]

Options:
  (no arg)    构建默认平台: win32, macos, linux32
  --all       构建全部平台
  --clean     删除所有构建产物
  --help      显示本帮助
EOF
}

# --- 参数处理 ---
case "${1:-}" in
  --clean)
    clean_all
    exit 0
    ;;
  --help|-h)
    usage
    exit 0
    ;;
  --all)
    PLATFORMS=(
      build_win32
      build_win64
      build_macos_intel
      build_macos_apple_silicon
      build_macos
      build_linux32
      build_linux64
      build_linux_arm64
      build_linux_arm
    )
    ;;
  "")
    PLATFORMS=(
      build_win32
      build_macos
      build_linux32
      build_linux_arm
    )
    ;;
  *)
    echo "[ERROR] 未知参数: $1" >&2
    usage
    exit 1
    ;;
esac

for platform in "${PLATFORMS[@]}"; do
  "$platform"
  echo
done