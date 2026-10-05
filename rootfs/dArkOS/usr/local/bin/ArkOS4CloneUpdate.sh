#!/bin/bash

# ArkOS4Clone 设备端升级入口 (对应 dArkOS 的 Update.sh)
# 放在设备上原 Update.sh 的位置,用户在设置里点"更新"时执行
# 离线模式: 把 ArkOS4CloneUpdate.sh 放进 /roms/update (或 /roms2/update),
#          对应日期的分卷放 /roms/update/<日期>/; 检测到本地脚本就直接执行,不走联网;
#          成功后自动删掉用过的脚本和分卷日期文件夹

if [[ "$(stat -c "%U" /home/ark)" != "ark" ]]; then
  printf "Fixing home folder permissions.  Please wait..."
  sudo chown -R ark:ark /home/ark
  sudo chmod -R 755 /home/ark
fi

printf "\nChecking for updates.  Please wait..."

LOG_FILE="/home/ark/esupdate.log"

if [ -f "$LOG_FILE" ]; then
  sudo mv -f "$LOG_FILE" "$LOG_FILE.old"
fi

sudo timedatectl set-ntp 1

LOCATION="https://raw.githubusercontent.com/lcdyk0517/arkos4clone-updates/master/update_files"

# ---- 离线模式检测: 本地已有升级脚本就直接用 ----
LOCAL_DIR=""
for d in /roms/update /roms2/update; do
  if [ -f "$d/ArkOS4CloneUpdate.sh" ]; then
    LOCAL_DIR="$d"
    break
  fi
done

if [ -n "$LOCAL_DIR" ]; then
  RUN_SCRIPT="$LOCAL_DIR/ArkOS4CloneUpdate.sh"
  printf "\nUsing local update script in ${LOCAL_DIR}..."
else
  RUN_SCRIPT="/home/ark/ArkOS4CloneUpdate.sh"
  sudo rm -f "$RUN_SCRIPT"
  wget -t 3 -T 60 --no-check-certificate "$LOCATION"/ArkOS4CloneUpdate.sh -O "$RUN_SCRIPT" -a "$LOG_FILE"
  if [ $? -ne 0 ] || [ ! -s "$RUN_SCRIPT" ]; then
    sudo rm -f "$RUN_SCRIPT"
    sudo msgbox "Looks like OTA updating is currently down or your wifi or internet connection is not functioning correctly."
    printf "There was an error with attempting this update." | tee -a "$LOG_FILE"
    exit 1
  fi
fi

sudo chmod -v 777 "$RUN_SCRIPT" | tee -a "$LOG_FILE"

# 升级脚本成功后会自删, 日期要先取出来供离线清理用
UPDATE_DATE="$(grep -m1 '^UPDATE_DATE=' "$RUN_SCRIPT" 2>/dev/null | tr -dc '0-9')"

"$RUN_SCRIPT"

if [ $? -ne 187 ]; then
  # 具体错误已由升级脚本弹窗说明; 离线脚本保留在原地便于排查, 只清理联网下载的脚本
  printf "There was an error with attempting this update." | tee -a "$LOG_FILE"
  if [ -z "$LOCAL_DIR" ] && [ -f "$RUN_SCRIPT" ]; then
    rm -f "$RUN_SCRIPT"
  fi
else
  # 升级完成: 离线模式下删掉用过的脚本 + 所有已应用日期的分卷文件夹, 联网模式下删掉下载的脚本
  if [ -n "$LOCAL_DIR" ]; then
    rm -f "$LOCAL_DIR/ArkOS4CloneUpdate.sh"
    for d in "$LOCAL_DIR"/[0-9]*; do
      [ -d "$d" ] || continue
      DATE_NAME="$(basename "$d")"
      case "$DATE_NAME" in
        [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;;
        *) continue ;;
      esac
      if [ -f "/home/ark/.update/.${DATE_NAME}" ]; then
        sudo rm -rf "$d"
      fi
    done
  elif [ -f "$RUN_SCRIPT" ]; then
    rm -f "$RUN_SCRIPT"
  fi
fi

if [ ! -z "$(pidof rg351p-js2xbox)" ]; then
  sudo kill -9 "$(pidof rg351p-js2xbox)"
  sudo rm -f /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
fi
