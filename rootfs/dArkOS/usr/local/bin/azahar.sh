#!/bin/bash
# Azahar (3DS) 专用启动: RetroArch 的 gl 驱动下 core 会 shader 失败崩溃,
# 必须走 Vulkan; 且 Mali 官方 blob 没有 KHR_display, 用自编 malisx2.
# savefiles_in_content_dir=false: 存档/用户目录固定为 savefile_directory/Azahar,
# 否则 core 会把 user dir 指到游戏目录, 字库和 DLC 每次都要按目录重装。

# ARMSX2 同样需要 Vulkan, 4.4 内核没有: 提示后等待 A/B，避免黑屏退回 ES.
case "$(uname -r)" in
  4.4*)
    export TERM=linux
    sudo chmod 666 /dev/tty1 2>/dev/null
    printf "\033c" > /dev/tty1
    dialog --title "Azahar" --infobox $'Vulkan is not available on the 4.4 kernel.\n\nSwitch to the 5.10 kernel and launch the 3DS game again.\n\nPress A or B to exit.' 12 64 > /dev/tty1 2>&1
    . /usr/local/bin/buttonmon.sh 2>/dev/null
    dev="/dev/input/event${event_num:-2}"
    btn_a="${event_btn_a:-BTN_EAST}"
    btn_b="${event_btn_b:-BTN_SOUTH}"
    while :; do
      evtest --query "$dev" EV_KEY "$btn_a" >/dev/null 2>&1
      [ $? -eq 10 ] && break
      evtest --query "$dev" EV_KEY "$btn_b" >/dev/null 2>&1
      [ $? -eq 10 ] && break
      sleep 0.1
    done
    printf "\033c" > /dev/tty1
    exit 0
    ;;
esac

export VK_ICD_FILENAMES=/opt/malisx2/malisx2.json
CFG=/tmp/azahar-video.cfg
# sort_savefiles_enable would hand the core a save dir already named after it
# (saves/Azahar), and the core appends another Azahar/ - the NAND the dec
# script fills would then never be seen.
printf 'video_driver = "vulkan"\nsavefiles_in_content_dir = "false"\nsort_savefiles_enable = "false"\n' > "$CFG"
exec /usr/local/bin/retroarch -c /home/ark/.config/retroarch/retroarch.cfg \
  --appendconfig "$CFG" \
  -L /home/ark/.config/retroarch/cores/azahar_libretro.so "$@"
