#!/usr/bin/env bash
set -euo pipefail

# ArkOS4Clone 一键构建脚本
# 用法: sudo ./build_image.sh <镜像路径> [工作目录]
# 工作目录用于存放镜像副本和处理文件，建议使用 ext4 文件系统以获得最佳性能

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 时间戳格式 (与 clone_support.sh 一致)
BUILD_DATE="$(TZ=Asia/Shanghai date +%m%d%Y)"
OUTPUT_NAME="ArkOS4Clone-${BUILD_DATE}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    log_error "请使用 sudo 运行此脚本"
    exit 1
  fi
}

check_image() {
  local img="$1"
  if [[ ! -f "$img" ]]; then
    log_error "镜像文件不存在: $img"
    exit 1
  fi
  if [[ ! -r "$img" ]]; then
    log_error "无法读取镜像文件: $img"
    exit 1
  fi
  log_ok "源镜像: $img"
}

check_tools() {
  local tools=(losetup mount umount parted rsync dd xz)
  for t in "${tools[@]}"; do
    if ! command -v "$t" >/dev/null 2>&1; then
      log_error "缺少工具: $t"
      exit 1
    fi
  done
  log_ok "必需工具检查通过"
}

check_uboot_files() {
  local uboot_dir="$SCRIPT_DIR/uboot"
  local files=("idbloader.img" "uboot.img" "trust.img" "flash_uboot.sh")
  for f in "${files[@]}"; do
    if [[ ! -f "$uboot_dir/$f" ]]; then
      log_error "缺少 U-Boot 文件: $uboot_dir/$f"
      exit 1
    fi
  done
  log_ok "U-Boot 文件检查通过"
}

check_jdk_file() {
  local jdk_file="zulu11.48.21-ca-jdk11.0.11-linux_aarch64.tar.gz"
  local jdk_url="https://cdn.azul.com/zulu-embedded/bin/zulu11.48.21-ca-jdk11.0.11-linux_aarch64.tar.gz"
  
  if [[ -f "$SCRIPT_DIR/$jdk_file" ]]; then
    log_ok "JDK 文件已存在: $jdk_file"
    return
  fi
  
  log_info "下载 JDK 文件..."
  # 以原用户身份下载（避免权限问题）
  if [[ -n "${SUDO_USER:-}" ]]; then
    if sudo -u "$SUDO_USER" wget $WGET_OPTS -O "$SCRIPT_DIR/$jdk_file" "$jdk_url"; then
      log_ok "JDK 下载完成: $jdk_file"
    else
      log_error "JDK 下载失败"
      sudo -u "$SUDO_USER" rm -f "$SCRIPT_DIR/$jdk_file" 2>/dev/null || true
      exit 1
    fi
  else
    if wget $WGET_OPTS -O "$SCRIPT_DIR/$jdk_file" "$jdk_url"; then
      log_ok "JDK 下载完成: $jdk_file"
    else
      log_error "JDK 下载失败"
      rm -f "$SCRIPT_DIR/$jdk_file" 2>/dev/null || true
      exit 1
    fi
  fi
}

check_pm_libs() {
  local pm_libs_dir="$SCRIPT_DIR/bin/pm_libs"
  local runtimes_url="https://github.com/PortsMaster/PortMaster-New/releases/download/2026-08-05_0732/runtimes.all.aarch64.zip"

  # 需要的文件列表
  local required_files=(
    "ags_3.6.squashfs"
    "dotnet-8.0.12.squashfs"
    "frt_2.1.6.squashfs"
    "frt_3.0.6_v1.squashfs"
    "frt_3.1.2.squashfs"
    "frt_3.2.3.squashfs"
    "frt_3.3.4.squashfs"
    "frt_3.4.5.squashfs"
    "frt_3.5.2.squashfs"
    "frt_3.5.3.squashfs"
    "frt_3.6.squashfs"
    "frt_4.0.4.squashfs"
    "frt_4.1.3.squashfs"
    "gmtoolkit.squashfs"
    "godot_4.2.2.mono.squashfs"
    "godot_4.2.2.squashfs"
    "godot_4.3.mono.squashfs"
    "godot_4.3.squashfs"
    "godot_4.4.1.mono.squashfs"
    "godot_4.4.1.squashfs"
    "godot_4.4.mono.squashfs"
    "godot_4.4.squashfs"
    "godot_4.5.mono.squashfs"
    "godot_4.5.squashfs"
    "godot_4.6.3.mono.squashfs"
    "godot_4.6.3.squashfs"
    "godot_4.7.1.mono.squashfs"
    "godot_4.7.1.squashfs"
    "mesa_pkg_0.1.squashfs"
    "mono-6.12.0.122-aarch64.squashfs"
    "python_3.11.squashfs"
    "pyxel_2.2.8_python_3.11.squashfs"
    "pyxel_2.3.18_python_3.11.squashfs"
    "pyxel_2.4.6_python_3.11.squashfs"
    "pyxel_2.9.5_python_3.11.squashfs"
    "renpy_8.1.3.squashfs"
    "renpy_8.3.4.squashfs"
    "rlvm.squashfs"
    "solarus-1.6.5.squashfs"
    "weston_pkg_0.2.squashfs"
    "zulu11.48.21-ca-jdk11.0.11-linux.squashfs"
    "zulu17.48.15-ca-jdk17.0.10-linux.squashfs"
    "zulu17.54.21-ca-jre17.0.13-linux.squashfs"
    "zulu23.32.11-ca-jre23.0.2-linux.squashfs"
    "zulu8.86.0.25-ca-jdk8.0.452-linux.squashfs"
  )

  # 检查目录是否存在
  if [[ ! -d "$pm_libs_dir" ]]; then
    mkdir -p "$pm_libs_dir"
  fi

  # 检查缺少的文件
  local missing=0
  for f in "${required_files[@]}"; do
    if [[ ! -f "$pm_libs_dir/$f" ]]; then
      missing=1
      break
    fi
  done

  if [[ $missing -eq 0 ]]; then
    log_ok "pm_libs 文件完整"
    return
  fi

  log_info "下载 PortMaster runtimes (约 1.6GB)..."
  local zip_file="$pm_libs_dir/runtimes.zip"

  # 下载
  if [[ -n "${SUDO_USER:-}" ]]; then
    if sudo -u "$SUDO_USER" wget $WGET_OPTS -O "$zip_file" "$runtimes_url"; then
      log_ok "runtimes 下载完成"
    else
      log_error "runtimes 下载失败"
      sudo -u "$SUDO_USER" rm -f "$zip_file" 2>/dev/null || true
      exit 1
    fi
    # 解压
    log_info "解压 runtimes..."
    sudo -u "$SUDO_USER" unzip -o -q "$zip_file" -d "$pm_libs_dir"
    sudo -u "$SUDO_USER" rm -f "$zip_file"
  else
    if wget $WGET_OPTS -O "$zip_file" "$runtimes_url"; then
      log_ok "runtimes 下载完成"
    else
      log_error "runtimes 下载失败"
      rm -f "$zip_file" 2>/dev/null || true
      exit 1
    fi
    # 解压
    log_info "解压 runtimes..."
    unzip -o -q "$zip_file" -d "$pm_libs_dir"
    rm -f "$zip_file"
  fi

  log_ok "pm_libs 文件准备完成"
}

check_work_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    log_info "创建工作目录: $dir"
    mkdir -p "$dir"
  fi
  # 检查是否可写
  if [[ ! -w "$dir" ]]; then
    log_error "工作目录不可写: $dir"
    exit 1
  fi
  log_ok "工作目录: $dir"
}

check_portmaster() {
  local pm_dir="$SCRIPT_DIR/PortMaster"
  local pm_url="https://github.com/PortsMaster/PortMaster-GUI/releases/download/2026.07.28-1212/PortMaster.zip"

  if [[ -d "$pm_dir" && -f "$pm_dir/PortMaster.sh" ]]; then
    log_ok "PortMaster 目录已存在"
    return
  fi

  log_info "下载 PortMaster..."
  local zip_file="$SCRIPT_DIR/PortMaster.zip"

  if [[ -n "${SUDO_USER:-}" ]]; then
    if sudo -u "$SUDO_USER" wget $WGET_OPTS -O "$zip_file" "$pm_url"; then
      log_ok "PortMaster 下载完成"
    else
      log_error "PortMaster 下载失败"
      sudo -u "$SUDO_USER" rm -f "$zip_file" 2>/dev/null || true
      exit 1
    fi
    log_info "解压 PortMaster..."
    sudo -u "$SUDO_USER" unzip -q -o "$zip_file" -d "$SCRIPT_DIR"
    sudo -u "$SUDO_USER" rm -f "$zip_file"
  else
    if wget $WGET_OPTS -O "$zip_file" "$pm_url"; then
      log_ok "PortMaster 下载完成"
    else
      log_error "PortMaster 下载失败"
      rm -f "$zip_file" 2>/dev/null || true
      exit 1
    fi
    log_info "解压 PortMaster..."
    unzip -q -o "$zip_file" -d "$SCRIPT_DIR"
    rm -f "$zip_file"
  fi

  log_ok "PortMaster 准备完成"
}

check_clone_dependencies() {
  log_info "检查 clone_support.sh 依赖..."
  local missing=0
  local missing_list=""

  # 检查必需目录
  local dirs=(
    "consoles"
    "bin"
    "bin/aic8800DC"
    "bin/json-c3"
    "mod_so/32"
    "mod_so/64"
    "replace_file"
    "replace_file/drastic"
    "replace_file/drastic-kk"
    "replace_file/onscripter"
    "replace_file/retroarch"
    "replace_file/ppsspp"
    "replace_file/flycastsa"
    "replace_file/freej2mesa"
    "replace_file/rufflesa"
    "replace_file/gametank"
    "replace_file/pymo"
    "replace_file/resources"
    "replace_file/retrorun"
    "replace_file/scummvm"
    "replace_file/services"
    "replace_file/yabasanshiro"
    "replace_file/tools"
    "res"
    "sh"
    "Jason3_Scripte"
    "Jason3_Scripte/Bluetooth-Manager"
    "Jason3_Scripte/GhostLoader"
    "Jason3_Scripte/InfoSystem"
    "Jason3_Scripte/wifi-toggle"
  )

  for d in "${dirs[@]}"; do
    if [[ ! -d "$SCRIPT_DIR/$d" ]]; then
      missing=1
      missing_list="$missing_list\n  缺少目录: $d"
    fi
  done

  # 检查必需文件
  local files=(
    "dtb_selector_macos"
    "dtb_selector_win32.exe"
    "sh/clone.sh"
    "sh/expandtoexfat.sh"
    "sh/darkos-expandtoexfat.sh"
    "bin/mcu_led"
    "bin/ws2812"
    "bin/sdljoymap"
    "bin/sdljoytest"
    "bin/console_detect"
    "replace_file/351Files"
    "replace_file/es_systems.cfg"
    "replace_file/es_systems.cfg.dual"
    "replace_file/emulationstation"
    "replace_file/pymo/cpymo"
    "replace_file/pymo/pymo.sh"
    "replace_file/pymo/Scan_for_new_games.pymo"
    "replace_file/retrorun/retrorun"
    "replace_file/retrorun/retrorun32"
    "replace_file/services/351mp.service"
    "Jason3_Scripte/Bluetooth-Manager/Bluetooth Manager.sh"
    "Jason3_Scripte/Bluetooth-Manager/patch.pak"
    "Jason3_Scripte/GhostLoader/GhostLoader.sh"
    "Jason3_Scripte/InfoSystem/InfoSystem.sh"
    "Jason3_Scripte/wifi-toggle/Wifi-toggle.sh"
  )

  for f in "${files[@]}"; do
    if [[ ! -f "$SCRIPT_DIR/$f" ]]; then
      missing=1
      missing_list="$missing_list\n  缺少文件: $f"
    fi
  done

  if [[ $missing -eq 1 ]]; then
    log_error "clone_support.sh 依赖检查失败"
    echo -e "$missing_list"
    exit 1
  fi

  log_ok "clone_support.sh 依赖检查通过"
}

step_build_dtb_selector() {
  log_info "步骤 0: 编译 dtb_selector 工具..."
  if [[ -f "$SCRIPT_DIR/build_dtb_selector.sh" ]]; then
    cd "$SCRIPT_DIR"
    # 以原用户身份执行编译（保留 PATH 环境变量）
    if [[ -n "${SUDO_USER:-}" ]]; then
      if sudo -u "$SUDO_USER" env PATH="$PATH" ./build_dtb_selector.sh; then
        log_ok "dtb_selector 编译完成"
      else
        log_warn "dtb_selector 编译失败，跳过（可能已存在）"
      fi
    else
      if ./build_dtb_selector.sh; then
        log_ok "dtb_selector 编译完成"
      else
        log_warn "dtb_selector 编译失败，跳过（可能已存在）"
      fi
    fi
    cd - > /dev/null
  else
    log_warn "未找到 build_dtb_selector.sh，跳过"
  fi
}

copy_image() {
  local src="$1"
  local dst="$2"
  log_info "复制源镜像到工作目录..."
  cp "$src" "$dst"
  log_ok "已创建工作副本: $dst"
}

step_grow() {
  local img="$1"
  log_info "步骤 2/7: 扩容镜像分区..."
  if "$SCRIPT_DIR/grow_p2_plus.sh" "$img"; then
    log_ok "分区扩容完成"
  else
    log_error "分区扩容失败"
    exit 1
  fi
}

step_flash_uboot() {
  local img="$1"
  log_info "步骤 3/7: 写入 U-Boot..."
  # 需要在 uboot 目录下执行，并使用绝对路径
  local abs_img
  if [[ "$img" = /* ]]; then
    abs_img="$img"
  else
    abs_img="$(pwd)/$img"
  fi
  cd "$SCRIPT_DIR/uboot"
  if ./flash_uboot.sh -y -i "$abs_img"; then
    log_ok "U-Boot 写入完成"
  else
    log_error "U-Boot 写入失败"
    cd "$SCRIPT_DIR"
    exit 1
  fi
  cd "$SCRIPT_DIR"
}

step_mount() {
  local img="$1"
  log_info "步骤 4/7: 挂载镜像..."
  if "$SCRIPT_DIR/mount_arkos.sh" mount "$img"; then
    log_ok "镜像挂载完成"
  else
    log_error "镜像挂载失败"
    exit 1
  fi
}

step_inject() {
  log_info "步骤 5/7: 注入定制内容..."
  if "$SCRIPT_DIR/clone_support.sh"; then
    log_ok "内容注入完成"
  else
    log_error "内容注入失败"
    # 尝试卸载
    "$SCRIPT_DIR/mount_arkos.sh" unmount 2>/dev/null || true
    exit 1
  fi
}

step_unmount() {
  log_info "步骤 6/7: 卸载镜像..."
  if "$SCRIPT_DIR/mount_arkos.sh" unmount; then
    log_ok "镜像卸载完成"
  else
    log_error "镜像卸载失败"
    exit 1
  fi
}

step_compress() {
  local img="$1"
  local xz_file="${img}.xz"
  log_info "步骤 7/7: 压缩镜像 (xz -5)..."
  
  # 压缩等级 5，多线程
  if xz -5 -T0 -v "$img"; then
    log_ok "压缩完成: $xz_file"
    log_ok "文件大小: $(du -h "$xz_file" | cut -f1)"
  else
    log_error "压缩失败"
    exit 1
  fi
}

move_to_script_dir() {
  local xz_file="$1"
  local dest="$SCRIPT_DIR/$(basename "$xz_file")"
  log_info "移动输出文件到脚本目录..."
  mv "$xz_file" "$dest" || true
  log_ok "输出文件: $dest"
}

show_usage() {
  cat << USAGE
ArkOS4Clone 一键构建脚本

用法:
  sudo ./build_image.sh <源镜像路径> [工作目录] [--ci]

参数:
  源镜像路径    必需，原始 ArkOS 镜像文件路径
  工作目录      可选，用于存放镜像副本和处理文件
                建议使用 ext4 文件系统以获得最佳性能
                默认: 源镜像所在目录
  --ci          可选，静默模式，减少下载进度等刷屏日志

环境变量:
  ARKOS_MNT       挂载路径 (默认: <工作目录>/mnt)
  ARKOS_WORK_DIR  临时工作目录 (默认: <工作目录>)

示例:
  # 使用默认工作目录（源镜像所在目录）
  sudo ./build_image.sh /path/to/ArkOS-*.img

  # 指定工作目录（推荐，使用 ext4 文件系统）
  sudo ./build_image.sh /mnt/e/ArkOS.img /home/lcdyk/arkos

执行步骤:
  0. 编译 dtb_selector 工具 (build_dtb_selector.sh)
  1. 复制源镜像到工作目录
  2. 扩容镜像分区 (grow_p2_plus.sh)
  3. 写入 U-Boot (flash_uboot.sh)
  4. 挂载镜像 (mount_arkos.sh mount)
  5. 注入定制内容 (clone_support.sh)
  6. 卸载镜像 (mount_arkos.sh unmount)
  7. 压缩为 xz 格式 (等级 5)
  8. 移动输出文件到脚本目录

输出:
  <脚本目录>/ArkOS4Clone-MMDDYYYY.img.xz

注意:
  - 源镜像文件不会被修改
  - 工作目录建议使用 ext4 文件系统，避免 WSL 的 /mnt 路径以提高性能

USAGE
}

main() {
  # 首先检查 root 权限
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    log_error "请使用 sudo 运行此脚本"
    exit 1
  fi

  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_usage
    exit 0
  fi

  if [[ $# -lt 1 ]]; then
    log_error "缺少参数: 镜像路径"
    echo ""
    show_usage
    exit 1
  fi

  local source_image="$1"
  
  # 确定工作目录
  local work_dir
  if [[ $# -ge 2 ]]; then
    work_dir="$2"
  else
    # 默认使用源镜像所在目录
    work_dir="$(cd "$(dirname "$source_image")" && pwd)"
  fi
  
  # 转换为绝对路径
  if [[ "$work_dir" != /* ]]; then
    work_dir="$(pwd)/$work_dir"
  fi

  # 设置环境变量
  ARKOS_MNT="${ARKOS_MNT:-${work_dir}/mnt}"
  ARKOS_WORK_DIR="${ARKOS_WORK_DIR:-${work_dir}}"
  ARKOS_IMAGE_NAME="$(basename "$source_image")"
  export ARKOS_MNT ARKOS_WORK_DIR ARKOS_IMAGE_NAME

  # 第三个参数 --ci: 静默模式，减少 CI 环境下的刷屏日志
  if [[ "${3:-}" == "--ci" ]]; then
    WGET_OPTS="-q"
    export ARKOS_QUIET=1
  else
    WGET_OPTS="-q --show-progress"
  fi

  # 根据源镜像名决定输出前缀
  local output_prefix
  if [[ "$ARKOS_IMAGE_NAME" == *dArkOS* ]]; then
    output_prefix="dArkOS4Clone"
  else
    output_prefix="ArkOS4Clone"
  fi
  local work_image="${work_dir}/${output_prefix}-${BUILD_DATE}.img"

  echo "========================================"
  echo "  ArkOS4Clone 一键构建脚本"
  echo "========================================"
  echo "源镜像:   $source_image"
  echo "工作目录: $work_dir"
  echo "工作副本: $work_image"
  echo "挂载路径: $ARKOS_MNT"
  echo "========================================"
  echo ""

  # 步骤 0: 编译 dtb_selector (不需要 root)
  step_build_dtb_selector
  echo ""

  # 前置检查 (不需要 root)
  check_tools
  check_jdk_file
  check_portmaster
  check_pm_libs
  check_clone_dependencies

  # 需要 root 的检查
  check_image "$source_image"
  check_work_dir "$work_dir"
  check_uboot_files

  # 步骤 1: 复制镜像
  echo ""
  copy_image "$source_image" "$work_image"

  # 执行构建流程
  echo ""
  step_grow "$work_image"
  echo ""
  step_flash_uboot "$work_image"
  echo ""
  step_mount "$work_image"
  echo ""
  step_inject
  echo ""
  step_unmount

  # 压缩并移动
  echo ""
  step_compress "$work_image"
  move_to_script_dir "${work_image}.xz"

  echo ""
  echo "========================================"
  log_ok "构建完成!"
  echo "输出文件: $SCRIPT_DIR/$(basename "${work_image}").xz"
  echo "源文件保留: $source_image"
  echo "========================================"
}

main "$@"
