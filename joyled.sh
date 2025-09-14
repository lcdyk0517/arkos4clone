#!/usr/bin/env bash
# Joystick LED Controller (multi-device, dialog-based)
# Author: lcdyk
#
# Backends:
#   - mcu_led : (xf35h / xf40h) GPIO65 + UART(/dev/ttyS2) + mcu_led chgmode
#   - mymini  : (mymini)        Linux LED class (/sys/class/leds/*/brightness)
#   - ws2812  : (xf40v / xf35v) 外部 ws2812ctl 包装器（可自带 glibc 启动）
#
# 约定：
#   * 首次进入不改变 LED 状态
#   * 选择项立即生效，成功静默，失败弹框
#   * 未支持机型：展示 /boot/.console 后直接退出
#
# 依赖：dialog, sudo, tee
# 可选：/opt/inttools/gptokeyb（用摇杆导航菜单）

# ======================
# 配置区（便于集中修改）
# ======================
MCU_LED_BIN="${MCU_LED_BIN:-/usr/bin/mcu_led}"            # 或 /usr/local/bin/mcu_led
WS2812CTL_BIN="${WS2812CTL_BIN:-/usr/bin/ws2812ctl}"      # ws2812 启动包装器
GPTOKEYB_BIN="${GPTOKEYB_BIN:-/opt/inttools/gptokeyb}"
SDL_DB_PATH="${SDL_DB_PATH:-/opt/inttools/gamecontrollerdb.txt}"
KEYS_GPTK_PATH="${KEYS_GPTK_PATH:-/opt/inttools/keys.gptk}"
CONSOLE_FONT="${CONSOLE_FONT:-/usr/share/consolefonts/Lat7-Terminus16.psf.gz}"

# 设备与 GPIO/UART（mcu_led 后端）
UART_DEV="${UART_DEV:-/dev/ttyS2}"
GPIO_NUM="${GPIO_NUM:-65}"

# mymini LED 节点
LED_BLUE="${LED_BLUE:-/sys/class/leds/blue:joy/brightness}"
LED_GREEN="${LED_GREEN:-/sys/class/leds/green:joy/brightness}"
LED_RED="${LED_RED:-/sys/class/leds/red:joy/brightness}"

# 运行时与状态
CURR_TTY="${CURR_TTY:-/dev/tty1}"
STATE_DIR="${STATE_DIR:-/var/lib/joyled}"
STATE_FILE="${STATE_FILE:-${STATE_DIR}/state}"

# ======================
# 基本守护
# ======================
if [ "$(id -u)" -ne 0 ]; then
  exec sudo -- "$0" "$@"
fi
set -euo pipefail
export TERM=linux

# 机型识别 -> 后端
MODEL="$(cat /boot/.console 2>/dev/null || echo unknown)"
detect_backend() {
  case "${MODEL}" in
    xf35h|xf40h)          echo "mcu_led" ;;
    mymini|r36ultra)      echo "gpio"  ;;
    xf40v|xf35v)          echo "ws2812"  ;;
    *)                    echo "unsupported" ;;
  esac
}
BACKEND="$(detect_backend)"

# UI 初始化（不改 LED）
printf "\033c" > "$CURR_TTY"
printf "\e[?25l" > "$CURR_TTY"
[ -f "$CONSOLE_FONT" ] && setfont "$CONSOLE_FONT" || true
printf "\033c" > "$CURR_TTY"

# -----------------------
# Helpers
# -----------------------
tee_root() { sudo tee "$1" >/dev/null; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }
set_kv()   { if have_cmd set_setting; then set_setting "$@" || true; fi; }

fatal_missing_backend() {
  # 显示提示并在确认后退出
  local msg="$1"
  if have_cmd dialog; then
    dialog --msgbox "$msg" 7 68 > "$CURR_TTY"
  else
    echo "$msg"
    read -r -p "Press Enter to exit..." _
  fi
  printf "\e[?25h" > "$CURR_TTY"
  exit 0
}

# 启动前后端自检：缺失即提示并退出
backend_precheck() {
  case "$BACKEND" in
    mcu_led)
      if [ ! -x "$MCU_LED_BIN" ] && ! have_cmd mcu_led; then
        fatal_missing_backend "摇杆灯控制程序未找到：\n${MCU_LED_BIN}\n并且 'mcu_led' 不在 PATH。\n请安装后重试。"
      fi
      ;;
    ws2812)
      if [ ! -x "$WS2812CTL_BIN" ]; then
        fatal_missing_backend "摇杆灯控制程序未找到：\n${WS2812CTL_BIN}\n请安装后重试。"
      fi
      ;;
  esac
}

# 菜单项（按后端裁剪）
build_menu_items() {
  case "$BACKEND" in
    mcu_led)
      cat <<'EOF'
off Turn off LED
battery Battery service control
red Solid Red
green Solid Green
blue Solid Blue
orange Solid Orange
purple Solid Purple
cyan Solid Cyan
white Solid White
breath_red Breathing Red
breath_green Breathing Green
breath_blue Breathing Blue
breath_orange Breathing Orange
breath_purple Breathing Purple
breath_cyan Breathing Cyan
breath_white Breathing White
breath Breathing (generic)
flow Flow effect
EOF
      ;;
    gpio)
      cat <<'EOF'
off Turn off LED
battery Battery service control
red Solid Red
green Solid Green
blue Solid Blue
white Solid White
orange Solid Orange
yellow Solid Yellow
purple Solid Purple
EOF
      ;;
    ws2812)
      cat <<'EOF'
off Turn off LED
scrolling Scrolling effect
breathing General breathing
breathing_red Breathing Red
breathing_green Breathing Green
breathing_blue Breathing Blue
breathing_blue_red Breathing Blue+Red
breathing_green_blue Breathing Green+Blue
breathing_red_green Breathing Red+Green
breathing_red_green_blue Breathing RGB
red_green_blue Solid RGB (white-ish)
blue_red Solid Magenta
blue Solid Blue
green_blue Solid Cyan
green Solid Green
red_green Solid Yellow/Orange-ish
red Solid Red
EOF
      ;;
  esac
}

choice_exists_in_menu() {
  local target="$1"
  mapfile -t LINES < <(build_menu_items)
  for ((i=0; i<${#LINES[@]}; i++)); do
    local tag="${LINES[$i]%% *}"
    [[ "$tag" == "$target" ]] && return 0
  done
  return 1
}

# -----------------------
# Backend: mcu_led
# -----------------------
GPIO_BASE="/sys/class/gpio"
GPIO_DIR="${GPIO_BASE}/gpio${GPIO_NUM}"

ensure_gpio() {
  if [[ ! -d "${GPIO_DIR}" ]]; then
    echo "${GPIO_NUM}" | tee_root "${GPIO_BASE}/export"
  fi
  if [[ -w "${GPIO_DIR}/direction" ]]; then
    echo out | tee_root "${GPIO_DIR}/direction"
  fi
}
gpio_on()  { echo 1 | tee_root "${GPIO_DIR}/value"; }
gpio_off() { echo 0 | tee_root "${GPIO_DIR}/value"; }

mode_code_mcu() {
  case "$1" in
    battery) echo 3  ;;
    red)     echo 3  ;;
    green)   echo 1  ;;
    blue)    echo 2  ;;
    white)   echo 7  ;;
    orange)  echo 5  ;;
    purple)  echo 6  ;;
    cyan)    echo 4  ;;
    breath_red)    echo 19 ;;
    breath_green)  echo 17 ;;
    breath_blue)   echo 18 ;;
    breath_white)  echo 23 ;;
    breath_orange) echo 21 ;;
    breath_purple) echo 22 ;;
    breath_cyan)   echo 20 ;;
    breath)        echo 24 ;;
    flow)          echo 8  ;;
    *)             echo "" ;;
  esac
}

run_mcu_led() {
  local mode="$1"
  if [ -x "$MCU_LED_BIN" ]; then
    "$MCU_LED_BIN" "${UART_DEV}" chgmode "${mode}" 1
  else
    mcu_led "${UART_DEV}" chgmode "${mode}" 1
  fi
}

apply_choice_mcu() {
  local name="$1"
  LAST_CHOICE="$name"

  if [[ "$name" == "off" ]]; then
    ensure_gpio
    gpio_off
    set_kv led.color "$name"
    mkdir -p "$STATE_DIR" && : > "$STATE_FILE" 2>/dev/null || true
    return 0
  fi

  local code; code="$(mode_code_mcu "$name")"
  if [[ -z "$code" ]]; then
    dialog --msgbox "Unknown mode: $name" 6 34 > "$CURR_TTY"
    return 1
  fi

  ensure_gpio
  gpio_on

  if run_mcu_led "$code"; then
    set_kv led.color "$name"
    mkdir -p "$STATE_DIR"; echo "$name" | sudo tee "$STATE_FILE" >/dev/null || true
    if [[ "$name" == "battery" ]] && have_cmd systemctl; then
      sudo systemctl restart batteryledstatus.service || true
    fi
  else
    dialog --msgbox "Failed to apply: $name (code $code)" 6 48 > "$CURR_TTY"
    return 1
  fi
}

# -----------------------
# Backend: gpio (LED class)
# -----------------------
led_disable_triggers() {
  for t in /sys/class/leds/*/trigger; do
    [ -w "$t" ] && echo none | sudo tee "$t" >/dev/null
  done
}
led_on_value() {
  local node="$1"
  local maxf="${node%/brightness}/max_brightness"
  if [ -r "$maxf" ]; then cat "$maxf"; else echo 1; fi
}
led_write() { echo "$2" | sudo tee "$1" >/dev/null; }
led_off_all() {
  [ -w "$LED_BLUE"  ] && led_write "$LED_BLUE"  0
  [ -w "$LED_GREEN" ] && led_write "$LED_GREEN" 0
  [ -w "$LED_RED"   ] && led_write "$LED_RED"   0
}
led_set_BGR() {
  [ -w "$LED_BLUE"  ] && led_write "$LED_BLUE"  "$1"
  [ -w "$LED_GREEN" ] && led_write "$LED_GREEN" "$2"
  [ -w "$LED_RED"   ] && led_write "$LED_RED"   "$3"
}

apply_choice_mymini() {
  local name="$1"
  LAST_CHOICE="$name"

  led_disable_triggers

  local B_ON G_ON R_ON
  B_ON="$(led_on_value "$LED_BLUE")"
  G_ON="$(led_on_value "$LED_GREEN")"
  R_ON="$(led_on_value "$LED_RED")"

  case "$name" in
    off)           led_off_all ;;
    battery|green) led_set_BGR 0       "$G_ON" 0       ;;
    blue)          led_set_BGR "$B_ON" 0       0       ;;
    red)           led_set_BGR 0       0       "$R_ON" ;;
    white)         led_set_BGR "$B_ON" "$G_ON" "$R_ON" ;;
    orange|yellow) led_set_BGR 0       "$G_ON" "$R_ON" ;;
    purple)        led_set_BGR "$B_ON" 0       "$R_ON" ;;
    *)             dialog --msgbox "Unknown/unsupported: $name" 6 50 > "$CURR_TTY"; return 1 ;;
  esac

  set_kv led.color "$name"
  mkdir -p "$STATE_DIR"; echo "$name" | sudo tee "$STATE_FILE" >/dev/null || true

  if [[ "$name" == "battery" ]] && have_cmd systemctl; then
    sudo systemctl restart batteryledstatus.service || true
  fi
  return 0
}

# -----------------------
# Backend: ws2812
# -----------------------

# 将菜单 tag 映射为 ws2812ctl 的精确模式名
ws2812_mode_arg() {
  case "$1" in
    off)                       echo "OFF" ;;
    scrolling)                 echo "Scrolling" ;;
    breathing)                 echo "Breathing" ;;
    breathing_red)             echo "Breathing_Red" ;;
    breathing_green)           echo "Breathing_Green" ;;
    breathing_blue)            echo "Breathing_Blue" ;;
    breathing_blue_red)        echo "Breathing_Blue_Red" ;;
    breathing_green_blue)      echo "Breathing_Green_Blue" ;;
    breathing_red_green)       echo "Breathing_Red_Green" ;;
    breathing_red_green_blue)  echo "Breathing_Red_Green_Blue" ;;
    red_green_blue)            echo "Red_Green_Blue" ;;
    blue_red)                  echo "Blue_Red" ;;
    blue)                      echo "Blue" ;;
    green_blue)                echo "Green_Blue" ;;
    green)                     echo "Green" ;;
    red_green)                 echo "Red_Green" ;;
    red)                       echo "Red" ;;
    *)                         echo "" ;;
  esac
}

# 杀掉已在运行的 ws2812ctl（若有）
kill_ws2812ctl_if_running() {
  # 根据二进制路径精确匹配
  pkill -f "^${WS2812CTL_BIN} " >/dev/null 2>&1 || true
}

# 杀掉已在运行的 ws2812ctl（若有）
kill_ws2812ctl_if_running() {
  # 根据二进制路径精确匹配
  pkill -f "^${WS2812CTL_BIN} " >/dev/null 2>&1 || true
}

# 以非阻塞方式启动 ws2812ctl；若有 coreutils 的 timeout 就用它
start_ws2812ctl_async() {
  local arg="$1"

  # 先清旧
  kill_ws2812ctl_if_running

  if command -v timeout >/dev/null 2>&1; then
    # 给个极短的启动窗口，避免阻塞当前脚本
    # 有些实现会在收到参数后自行常驻，这里用 timeout 让前台立刻返回
    timeout 0.3s "$WS2812CTL_BIN" "$arg" >/dev/null 2>&1 || true
    # 若还需要后台守护（部分实现会在 timeout 后退出），再补一手纯后台
    nohup "$WS2812CTL_BIN" "$arg" >/dev/null 2>&1 </dev/null &
  else
    # 直接后台 + 脱离终端
    nohup "$WS2812CTL_BIN" "$arg" >/dev/null 2>&1 </dev/null &
  fi

  # 简单确认：给系统调度一点时间
  sleep 0.05
  # 可选：检查是否有新进程在跑（不强制失败）
  pgrep -f "^${WS2812CTL_BIN} " >/dev/null 2>&1 || true
}


apply_choice_ws2812() {
  local name="$1"
  LAST_CHOICE="$name"

  local arg; arg="$(ws2812_mode_arg "$name")"
  if [[ -z "$arg" ]]; then
    dialog --msgbox "Unknown/unsupported: $name" 6 40 > "$CURR_TTY"
    return 1
  fi

  if [[ "$arg" == "OFF" ]]; then
    # 关灯：直接杀旧实例；如有需要，再发一次 OFF（后台瞬发）
    kill_ws2812ctl_if_running
    nohup "$WS2812CTL_BIN" "OFF" >/dev/null 2>&1 </dev/null &  # 某些固件要求显式发送 OFF
  else
    # 其他效果：非阻塞后台启动
    start_ws2812ctl_async "$arg"
  fi

  # 走到这里视为成功，不阻塞 UI
  set_kv led.color "$name"
  mkdir -p "$STATE_DIR"; echo "$name" | sudo tee "$STATE_FILE" >/dev/null || true
  return 0
}


# -----------------------
# Unsupported / Precheck
# -----------------------
unsupported_device_flow() {
  local tmpf="/tmp/console_model.txt"
  echo "---- /boot/.console ----" > "$tmpf"
  cat /boot/.console 2>/dev/null >> "$tmpf" || echo "(file missing)" >> "$tmpf"

  if have_cmd dialog; then
    dialog --backtitle "Joystick LED Controller - by lcdyk" \
           --title "Device Model" \
           --textbox "$tmpf" 12 60 > "$CURR_TTY"
  else
    cat "$tmpf"
    read -r -p "Press Enter to exit..." _
  fi
  printf "\e[?25h" > "$CURR_TTY"
  exit 0
}

# 可选摇杆导航与退出处理
ExitMenu() {
  printf "\033c" > "$CURR_TTY"
  printf "\e[?25h" > "$CURR_TTY"
  pkill -f "gptokeyb -1 joyled.sh" >/dev/null 2>&1 || true
  exit 0
}
trap ExitMenu EXIT SIGINT SIGTERM

if [ -x "$GPTOKEYB_BIN" ]; then
  [[ -e /dev/uinput ]] && chmod 666 /dev/uinput 2>/dev/null || true
  export SDL_GAMECONTROLLERCONFIG_FILE="$SDL_DB_PATH"
  pkill -f "gptokeyb -1 joyled.sh" >/dev/null 2>&1 || true
  "$GPTOKEYB_BIN" -1 "joyled.sh" -c "$KEYS_GPTK_PATH" >/dev/null 2>&1 &
else
  dialog --infobox "gptokeyb not found. Keyboard only." 5 50 > "$CURR_TTY"
  sleep 1
fi

# 未支持机型：展示后退出
if [[ "$BACKEND" == "unsupported" ]]; then
  unsupported_device_flow
fi

# 二进制缺失：提示后退出
backend_precheck

# -----------------------
# Main Menu
# -----------------------
LAST_CHOICE=""
if [[ -s "$STATE_FILE" ]]; then
  LAST_CHOICE="$(sudo cat "$STATE_FILE" 2>/dev/null || true)"
  choice_exists_in_menu "$LAST_CHOICE" || LAST_CHOICE=""
fi

MainMenu() {
  while true; do
    mapfile -t LINES < <(build_menu_items)
    MENU_OPTS=()
    for ((i=0; i<${#LINES[@]}; i++)); do
      local tag desc
      tag="${LINES[$i]%% *}"
      desc="${LINES[$i]#* }"
      MENU_OPTS+=("$tag" "$desc")
    done

    if [[ -n "$LAST_CHOICE" ]]; then
      CHOICE=$(dialog --output-fd 1 \
        --backtitle "Joystick LED Controller - by lcdyk | Model: ${MODEL} | Backend: ${BACKEND}" \
        --title "LED Mode Selection" \
        --default-item "$LAST_CHOICE" \
        --menu "Select LED color/effect" 20 60 12 \
        "${MENU_OPTS[@]}" 2>"$CURR_TTY" || true)
    else
      CHOICE=$(dialog --output-fd 1 \
        --backtitle "Joystick LED Controller - by lcdyk | Model: ${MODEL} | Backend: ${BACKEND}" \
        --title "LED Mode Selection" \
        --menu "Select LED color/effect" 20 60 12 \
        "${MENU_OPTS[@]}" 2>"$CURR_TTY" || true)
    fi

    [[ -z "${CHOICE:-}" ]] && ExitMenu

    case "$BACKEND" in
      mcu_led) apply_choice_mcu    "$CHOICE" || true ;;
      gpio)  apply_choice_mymini "$CHOICE" || true ;;
      ws2812)  apply_choice_ws2812 "$CHOICE" || true ;;
    esac
  done
}

printf "\033c" > "$CURR_TTY"
printf "Joystick LED Controller\nPlease wait..." > "$CURR_TTY"
printf "\n\nScript by lcdyk\nModel: %s\nBackend: %s" "$MODEL" "$BACKEND" > "$CURR_TTY"
sleep 0.25
printf "\033c" > "$CURR_TTY"
MainMenu
