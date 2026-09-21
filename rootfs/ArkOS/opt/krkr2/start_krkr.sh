#!/bin/bash
# KrKr2 Next - ArkOS launcher
# Usage: start_krkr.sh <game.xp3>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Function to check if any swap is already active
is_swap_active() {
    grep -q -E "zram0|swapfile" /proc/swaps 2>/dev/null
}

# Function to set up swap (try zram first, fallback to file)
setup_swap() {
    local size_mb=$1
    echo "Setting up swap with ${size_mb}MB..."

    # Try zram first
    if sudo modprobe zram 2>/dev/null; then
        echo "zram module loaded, using zram..."
        echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null || true
        echo ${size_mb}M > /sys/block/zram0/disksize
        sudo mkswap /dev/zram0 2>/dev/null
        sudo swapon /dev/zram0 -p 100 2>/dev/null
        if grep -q zram0 /proc/swaps 2>/dev/null; then
            echo "zram swap active."
            return 0
        fi
    fi

    # zram failed, fallback to swap file
    echo "zram failed, falling back to swap file..."
    sudo fallocate -l ${size_mb}M /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=${size_mb} status=none
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile 2>/dev/null
    sudo swapon /swapfile 2>/dev/null
    if grep -q /swapfile /proc/swaps 2>/dev/null; then
        echo "Swap file active."
    else
        echo "WARNING: Failed to set up swap!"
    fi
}

# Function to tear down swap
teardown_swap() {
    echo "Tearing down swap..."
    sudo swapoff /swapfile 2>/dev/null || true
    sudo rm -f /swapfile 2>/dev/null || true
    sudo swapoff /dev/zram0 2>/dev/null || true
    echo 1 > /sys/block/zram0/reset 2>/dev/null || true
}

# Check if swap is already active
SWAP_WAS_ACTIVE=false
if is_swap_active; then
    SWAP_WAS_ACTIVE=true
    echo "Swap already active, skipping setup."
else
    setup_swap 512
fi

# Cleanup function
cleanup_swap() {
    if [ "$SWAP_WAS_ACTIVE" = false ]; then
        teardown_swap
    fi
}
trap cleanup_swap EXIT

if [ -z "$1" ]; then
    cleanup_swap
    echo "Usage: $0 <game.xp3>"
    exit 1
fi

GAME_PATH="$1"

# 如果是相对路径，转为绝对路径
if [[ "$GAME_PATH" != /* ]]; then
    GAME_PATH="$(pwd)/$GAME_PATH"
fi

if [ ! -f "$GAME_PATH" ]; then
    cleanup_swap
    echo "Error: File not found: $GAME_PATH"
    exit 1
fi

# 获取游戏目录
GAME_DIR="$(dirname "$GAME_PATH")"

# 复制配置文件到游戏目录（如果不存在）
if [ -f "${SCRIPT_DIR}/Kirikiroid2Preference.xml" ] && [ ! -f "${GAME_DIR}/Kirikiroid2Preference.xml" ]; then
    cp "${SCRIPT_DIR}/Kirikiroid2Preference.xml" "${GAME_DIR}/Kirikiroid2Preference.xml"
fi

# 设置库路径
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"

# GO-Super 手柄配置
export SDL_GAMECONTROLLERCONFIG="190000004b4800000011000000010000,GO-Super Gamepad,x:b2,a:b1,b:b0,y:b3,back:b12,start:b13,dpleft:b10,dpdown:b9,dpright:b11,dpup:b8,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftstick:b14,rightstick:b15,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux,"

# 切换到游戏目录
cd "$GAME_DIR"

# 启动引擎（不用 exec，让 cleanup 能正常执行）
"${SCRIPT_DIR}/bin/krkr2" "$GAME_PATH"

# 游戏退出后清理 swap
cleanup_swap

exit $?