#!/bin/bash
# =========================================================
# ArkOS Manager - System Management Script
# Author: @lcdyk
# =========================================================

# Require root, otherwise re-execute with sudo
if [ "$(id -u)" -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi
set -euo pipefail

# TTY / sysfs paths
CURR_TTY="/dev/tty1"
CPU_SYSFS="/sys/devices/system/cpu"
GPU_SYSFS=$(ls -d /sys/class/devfreq/ff400000.gpu 2>/dev/null | head -n 1)

# Force English interface
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export TERM=linux
unset FBTERM

# Initialize terminal
printf "\033c" > "$CURR_TTY"
printf "\e[?25l" > "$CURR_TTY"   # hide cursor
setfont /usr/share/consolefonts/Lat7-Terminus16.psf.gz 2>/dev/null || true
printf "\033c" > "$CURR_TTY"
printf "ArkOS Manager\nPlease wait..." > "$CURR_TTY"
printf "\n\nScript by @lcdyk" > "$CURR_TTY"
sleep 1

# ---------------------------------------------------------
# Dialog safe wrappers to avoid ESC/Cancel causing exit with set -e
# ---------------------------------------------------------
safe_textbox() {
    # Usage: safe_textbox /path/to/file 22 90
    dialog --textbox "$1" "${2:-20}" "${3:-70}" > "$CURR_TTY" || true
}

safe_msgbox() {
    # Usage: safe_msgbox "message" 6 40
    dialog --msgbox "${1:-Done.}" "${2:-6}" "${3:-40}" > "$CURR_TTY" || true
}

safe_infobox() {
    # Usage: safe_infobox "Working..." 5 34
    dialog --infobox "${1:-Working...}" "${2:-5}" "${3:-34}" > "$CURR_TTY" || true
}

# ---------------------------------------------------------
# Common CPU helpers (dynamic cores)
# ---------------------------------------------------------
cpu_list() {
    local rng s e i
    if rng=$(cat "$CPU_SYSFS/present" 2>/dev/null) && [[ "$rng" =~ ^([0-9]+)-([0-9]+)$ ]]; then
        s=${BASH_REMATCH[1]}
        e=${BASH_REMATCH[2]}
        for ((i=s; i<=e; i++)); do
            echo "cpu$i"
        done
    else
        ls -d "$CPU_SYSFS"/cpu[0-9]* 2>/dev/null | xargs -n1 basename
    fi
}

cpu_count() {
    cpu_list | wc -l
}

# ---------------------------------------------------------
# GPU FUNCTIONS
# ---------------------------------------------------------
get_gpu_status() {
    local cur max min avails
    cur=$(cat "$GPU_SYSFS/cur_freq" 2>/dev/null || echo "N/A")
    max=$(cat "$GPU_SYSFS/max_freq" 2>/dev/null || echo "N/A")
    min=$(cat "$GPU_SYSFS/min_freq" 2>/dev/null || echo "N/A")
    avails=$(cat "$GPU_SYSFS/available_frequencies" 2>/dev/null || echo "")
    echo -e "Current: $cur\nMax: $max\nMin: $min\nAvailable:\n$avails"
}

set_gpu_max() {
    local freq="$1"
    if [[ -w "$GPU_SYSFS/max_freq" ]]; then
        echo "$freq" > "$GPU_SYSFS/max_freq"
    fi
}

choose_gpu_max() {
    local avails
    avails=($(cat "$GPU_SYSFS/available_frequencies" 2>/dev/null))
    if [[ ${#avails[@]} -eq 0 ]]; then
        safe_msgbox "Can't read GPU available frequencies!" 6 44
        return
    fi
    
    local menu_opts=()
    for f in "${avails[@]}"; do
        menu_opts+=("$f" "")
    done
    
    local title
    title="Select GPU max freq (Current: $(cat "$GPU_SYSFS/max_freq" 2>/dev/null || echo N/A))"
    
    local choice
    choice=$(dialog --output-fd 1 --menu "$title" 15 50 6 "${menu_opts[@]}" 2>"$CURR_TTY") || return
    
    if [[ -n "$choice" ]]; then
        set_gpu_max "$choice"
        safe_msgbox "GPU Max Freq set to $choice" 6 40
    fi
}

GPUMenu() {
    while true; do
        local STATUS
        STATUS=$(get_gpu_status)
        
        local CHOICE
        CHOICE=$(dialog --output-fd 1 \
            --backtitle "GPU Freq Manager - ArkOS Manager by @lcdyk" \
            --title "GPU Freq Manager" \
            --menu "Current GPU Status:\n$STATUS" 20 60 10 \
            1 "Choose Max Freq" \
            2 "Back" \
            2>"$CURR_TTY") || return
        
        case $CHOICE in
            1) choose_gpu_max ;;
            2) return ;;
            *) return ;;
        esac
    done
}

# ---------------------------------------------------------
# CPU FUNCTIONS (dynamic core count)
# ---------------------------------------------------------
get_cpu_status() {
    local status=""
    local c
    for c in $(cpu_list); do
        local cpu_path="$CPU_SYSFS/$c"
        local online=$(cat "$cpu_path/online" 2>/dev/null || echo 1)
        status+="$c: $([[ "$online" -eq 1 ]] && echo "ON" || echo "OFF")\n"
    done
    echo -e "$status"
}

cpu_is_online() {
    local c="$1"
    local p="$CPU_SYSFS/$c/online"
    if [[ -f "$p" ]]; then
        [[ "$(cat "$p")" -eq 1 ]]
    else
        return 0
    fi
}

toggle_cpu_core() {
    local cpu="$1"
    local cpu_path="$CPU_SYSFS/$cpu"
    if [[ ! -f "$cpu_path/online" ]]; then
        safe_msgbox "CPU $cpu cannot be toggled" 6 40
        return
    fi
    
    local online
    online=$(cat "$cpu_path/online")
    if [[ "$online" -eq 1 ]]; then
        echo 0 > "$cpu_path/online"
    else
        echo 1 > "$cpu_path/online"
    fi
}

set_all_cores() {
    local state="$1"
    local c
    for c in $(cpu_list); do
        local p="$CPU_SYSFS/$c/online"
        [[ -f "$p" ]] && echo "$state" > "$p"
    done
}

single_core_mode() {
    [[ -f "$CPU_SYSFS/cpu0/online" ]] && echo 1 > "$CPU_SYSFS/cpu0/online" 2>/dev/null || true
    
    local c
    for c in $(cpu_list); do
        [[ "$c" == "cpu0" ]] && continue
        local p="$CPU_SYSFS/$c/online"
        [[ -f "$p" ]] && echo 0 > "$p" 2>/dev/null || true
    done
    safe_msgbox "Switched to single-core mode (CPU0 only)" 6 50
}

full_core_mode() {
    set_all_cores 1
    safe_msgbox "All CPU cores enabled" 6 40
}

get_available_governors() {
    cat "$CPU_SYSFS/cpu0/cpufreq/scaling_available_governors" 2>/dev/null
}

get_current_governor() {
    local target="$1"
    if [[ "$target" == "all" ]]; then
        local govs=() c
        for c in $(cpu_list); do
            local f="$CPU_SYSFS/$c/cpufreq/scaling_governor"
            [[ -f "$f" ]] && govs+=("$(cat "$f")")
        done
        echo "${govs[*]}"
    else
        local f="$CPU_SYSFS/$target/cpufreq/scaling_governor"
        [[ -f "$f" ]] && cat "$f"
    fi
}

set_cpu_governor() {
    local target="$1" governor="$2"
    if [[ "$target" == "all" ]]; then
        local c
        for c in $(cpu_list); do
            local f="$CPU_SYSFS/$c/cpufreq/scaling_governor"
            [[ -f "$f" ]] && echo "$governor" > "$f"
        done
    else
        local f="$CPU_SYSFS/$target/cpufreq/scaling_governor"
        [[ -f "$f" ]] && echo "$governor" > "$f"
    fi
}

choose_governor() {
    local governors
    governors=($(get_available_governors))
    if [[ ${#governors[@]} -eq 0 ]]; then
        safe_msgbox "Can't read CPU supported governors!" 6 46
        return
    fi
    
    local menu_opts=() g
    for g in "${governors[@]}"; do
        menu_opts+=("$g" "")
    done
    
    local title_choose_gov="Select CPU governor (Current CPU0: $(get_current_governor cpu0))"
    local choice
    choice=$(dialog --output-fd 1 --menu "$title_choose_gov" 15 40 6 "${menu_opts[@]}" 2>"$CURR_TTY") || return
    [[ -z "$choice" ]] && return
    
    local tgt_opts=()
    tgt_opts+=("all" "All Cores (only online cores)")
    local c
    for c in $(cpu_list); do
        if cpu_is_online "$c"; then
            tgt_opts+=("$c" "$c ($(get_current_governor $c))")
        fi
    done
    
    local tgt_title="Choose target CPU (online cores only)"
    local target_choice
    target_choice=$(dialog --output-fd 1 --menu "$tgt_title" 12 50 8 "${tgt_opts[@]}" 2>"$CURR_TTY") || return
    
    case "$target_choice" in
        all) set_cpu_governor "all" "$choice" ;;
        cpu*) set_cpu_governor "$target_choice" "$choice" ;;
        *) return ;;
    esac
    safe_msgbox "Now in $choice governor" 6 40
}

get_available_freqs() {
    if [[ -f "$CPU_SYSFS/cpu0/cpufreq/scaling_available_frequencies" ]]; then
        cat "$CPU_SYSFS/cpu0/cpufreq/scaling_available_frequencies"
    fi
}

get_current_max_freq() {
    local target="$1"
    local f="$CPU_SYSFS/$target/cpufreq/scaling_max_freq"
    [[ -f "$f" ]] && cat "$f"
}

set_cpu_max_freq() {
    local target="$1" freq="$2"
    if [[ "$target" == "all" ]]; then
        local c
        for c in $(cpu_list); do
            local f="$CPU_SYSFS/$c/cpufreq/scaling_max_freq"
            [[ -f "$f" ]] && echo "$freq" > "$f"
        done
    else
        local f="$CPU_SYSFS/$target/cpufreq/scaling_max_freq"
        [[ -f "$f" ]] && echo "$freq" > "$f"
    fi
}

choose_max_freq() {
    local freqs
    freqs=($(get_available_freqs))
    if [[ ${#freqs[@]} -eq 0 ]]; then
        safe_msgbox "Can't read CPU frequencies!" 6 40
        return
    fi
    
    local menu_opts=() f
    for f in "${freqs[@]}"; do
        menu_opts+=("$f" "")
    done
    
    local title_max="Select Max CPU Frequency\n(Current CPU0: $(get_current_max_freq cpu0))"
    local choice
    choice=$(dialog --output-fd 1 --menu "$title_max" 20 50 10 "${menu_opts[@]}" 2>"$CURR_TTY") || return
    [[ -z "$choice" ]] && return
    
    local tgt_opts=()
    tgt_opts+=("all" "All Cores (only online cores)")
    local c
    for c in $(cpu_list); do
        if cpu_is_online "$c"; then
            tgt_opts+=("$c" "$c ($(get_current_max_freq $c))")
        fi
    done
    
    local tgt_title="Apply to: (online cores only)"
    local target_choice
    target_choice=$(dialog --output-fd 1 --menu "$tgt_title" 12 50 8 "${tgt_opts[@]}" 2>"$CURR_TTY") || return
    
    case "$target_choice" in
        all) set_cpu_max_freq "all" "$choice" ;;
        cpu*) set_cpu_max_freq "$target_choice" "$choice" ;;
        *) return ;;
    esac
    safe_msgbox "Now max freq is $choice" 6 40
}

CPUMenu() {
    while true; do
        local STATUS
        STATUS=$(get_cpu_status)
        
        local opts=()
        local core_map=()
        local idx=1
        local c
        for c in $(cpu_list); do
            opts+=("$idx" "Toggle ${c}")
            core_map[$idx]="$c"
            ((idx++))
        done
        
        local IDX_ENABLE_ALL=$idx
        opts+=("$IDX_ENABLE_ALL" "Enable All Cores")
        ((idx++))
        
        local IDX_CHOOSE_GOV=$idx
        opts+=("$IDX_CHOOSE_GOV" "Choose Governor")
        ((idx++))
        
        local IDX_SET_MAX=$idx
        opts+=("$IDX_SET_MAX" "Set Max CPU Frequency")
        ((idx++))
        
        local IDX_SINGLE=$idx
        opts+=("$IDX_SINGLE" "Single-Core Mode (CPU0 only)")
        ((idx++))
        
        local IDX_FULL=$idx
        opts+=("$IDX_FULL" "Full-Core Mode (All cores)")
        ((idx++))
        
        local IDX_BACK=$idx
        opts+=("$IDX_BACK" "Back")
        
        local CHOICE
        CHOICE=$(dialog --output-fd 1 \
            --backtitle "CPU Core Manager - ArkOS Manager by @lcdyk" \
            --title "CPU Core Manager" \
            --menu "Current CPU Status:\n$STATUS" 22 60 14 \
            "${opts[@]}" \
            2>"$CURR_TTY") || return
        
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [[ -n "${core_map[$CHOICE]:-}" ]]; then
            toggle_cpu_core "${core_map[$CHOICE]}"
            continue
        fi
        
        case "$CHOICE" in
            "$IDX_ENABLE_ALL") set_all_cores 1 ;;
            "$IDX_CHOOSE_GOV") choose_governor ;;
            "$IDX_SET_MAX") choose_max_freq ;;
            "$IDX_SINGLE") single_core_mode ;;
            "$IDX_FULL") full_core_mode ;;
            "$IDX_BACK") return ;;
            *) return ;;
        esac
    done
}

# ---------------------------------------------------------
# ZRAM FUNCTIONS
# ---------------------------------------------------------
# Default 512MB
ZRAM_SIZE_BYTES=536870912

get_zram_brief_status() {
    local z_present=0 z_size_kb=0 z_used_kb=0 z_pri="N/A"
    if grep -q '^/dev/zram0' /proc/swaps 2>/dev/null; then
        z_present=1
        read -r _ _ z_size_kb z_used_kb z_pri <<EOF
$(awk '/^\/dev\/zram0/{print $1" "$2" "$3" "$4" "$5}' /proc/swaps)
EOF
    fi
    
    _fmt_kb() {
        local kb=$1
        if [ "$kb" -ge 1048576 ]; then
            local gi=$((kb / 1048576))
            local rem=$((kb % 1048576))
            local tenth=$(( (rem * 10 + 524288) / 1048576 ))
            echo "${gi}.${tenth} GB"
        else
            local mb=$(( (kb + 512) / 1024 ))
            echo "${mb} MB"
        fi
    }
    
    if [ "$z_present" -eq 1 ]; then
        echo "ZRAM: enabled  size=$(_fmt_kb "$z_size_kb")  used=$(_fmt_kb "$z_used_kb")  prio=$z_pri"
    else
        echo "ZRAM: not enabled"
    fi
}

zram_show_status() {
    local mt_kb ma_kb mu_kb
    mt_kb=$(awk '/MemTotal:/{print $2}' /proc/meminfo)
    ma_kb=$(awk '/MemAvailable:/{print $2}' /proc/meminfo)
    mu_kb=$((mt_kb - ma_kb))
    
    fmt_kb() {
        local kb=$1
        if [ "$kb" -ge 1048576 ]; then
            local gi=$((kb / 1048576))
            local rem=$((kb % 1048576))
            local tenth=$(( (rem * 10 + 524288) / 1048576 ))
            echo "${gi}.${tenth} GB"
        else
            local mb=$(( (kb + 512) / 1024 ))
            echo "${mb} MB"
        fi
    }
    
    local z_present=0 z_size_kb=0 z_used_kb=0 z_pri="N/A"
    if grep -q '^/dev/zram0' /proc/swaps 2>/dev/null; then
        z_present=1
        read -r _ _ z_size_kb z_used_kb z_pri <<EOF
$(awk '/^\/dev\/zram0/{print $1" "$2" "$3" "$4" "$5}' /proc/swaps)
EOF
    fi
    
    local comp_line="" comp_ok=0
    if [ -r /sys/block/zram0/mm_stat ]; then
        local orig_b compr_b
        read -r orig_b compr_b _ < /sys/block/zram0/mm_stat
        if [ -n "${orig_b:-}" ] && [ -n "${compr_b:-}" ]; then
            comp_ok=1
            local ratio savings
            ratio=$(awk -v o="$orig_b" -v c="$compr_b" 'BEGIN{ if(c>0) printf "%.1f", o/c; else print "-" }')
            savings=$(awk -v o="$orig_b" -v c="$compr_b" 'BEGIN{ if(o>0) printf "%.0f", (1 - c/o)*100; else print "0" }')
            comp_line=$(printf " Compression: orig≈%s  compressed≈%s  ratio≈%s:1  saved≈%s%%\n" \
                "$(fmt_kb $(( (orig_b + 1023)/1024 )))" \
                "$(fmt_kb $(( (compr_b + 1023)/1024 )))" \
                "$ratio" "$savings")
        fi
    fi
    
    local other_swaps
    other_swaps=$(awk '!/^Filename/ && $1!="/dev/zram0"{printf "  %-16s %8d KB  pri=%s\n",$1,$3,$5}' /proc/swaps 2>/dev/null || true)
    
    local text=""
    text+="================= Memory / ZRAM Status =================\n"
    text+=" RAM Total : $(fmt_kb "$mt_kb")\n"
    text+=" RAM Used  : $(fmt_kb "$mu_kb")\n"
    text+=" RAM Avail : $(fmt_kb "$ma_kb")\n\n"
    
    if [ "$z_present" -eq 1 ]; then
        text+=" ZRAM      : enabled  size=$(fmt_kb "$z_size_kb")  used=$(fmt_kb "$z_used_kb")  prio=$z_pri\n"
        [ "$comp_ok" -eq 1 ] && text+="$comp_line"
    else
        text+=" ZRAM      : not enabled\n"
    fi
    
    if [ -n "$other_swaps" ]; then
        text+="\n Other swap devices:\n$other_swaps\n"
    fi
    text+="========================================================"
    
    printf "%s" "$text" > /tmp/zram_status.txt
    safe_textbox "/tmp/zram_status.txt" 20 70
}

choose_zram_size() {
    local opts=(
        134217728  "128 MB"
        268435456  "256 MB"
        536870912  "512 MB"
        1073741824 "1024 MB"
    )
    local title="Select ZRAM size (current: ${ZRAM_SIZE_BYTES} bytes)"
    local choice
    choice=$(dialog --output-fd 1 --menu "$title" 12 40 6 "${opts[@]}" 2>"$CURR_TTY") || return
    
    if [[ -n "$choice" ]]; then
        ZRAM_SIZE_BYTES="$choice"
        safe_msgbox "ZRAM size set to ${ZRAM_SIZE_BYTES} bytes" 6 50
    fi
}

zram_enable() {
    local size_bytes="${1:-${ZRAM_SIZE_BYTES:-536870912}}"
    local zdev="/dev/zram0"
    local zsys="/sys/block/zram0"
    
    safe_infobox "Enabling ZRAM, please wait..." 5 34
    swapoff -a 2>/dev/null || true
    modprobe zram 2>/dev/null || true
    
    if [ ! -e "$zsys" ] && [ -w /sys/class/zram-control/hot_add ]; then
        echo 0 > /sys/class/zram-control/hot_add 2>/dev/null || true
    fi
    
    if [ ! -e "$zsys" ]; then
        safe_msgbox "zram0 not present; cannot enable ZRAM" 6 46
        return
    fi
    
    grep -q "^$zdev" /proc/swaps 2>/dev/null && swapoff "$zdev" 2>/dev/null || true
    echo 1 > "$zsys/reset" 2>/dev/null || true
    
    if [ -w "$zsys/disksize" ]; then
        echo "$size_bytes" > "$zsys/disksize"
    else
        safe_msgbox "Cannot set zram disksize; permission or kernel issue" 7 60
        return
    fi
    
    [ -b "$zdev" ] || sleep 0.1
    mkswap "$zdev" >/dev/null 2>&1 || true
    swapon -p 5 "$zdev" 2>/dev/null || true
    
    if grep -q "^$zdev" /proc/swaps 2>/dev/null; then
        safe_msgbox "ZRAM enabled (size: ${size_bytes}B, priority: 5)" 6 60
    else
        safe_msgbox "Failed to enable ZRAM; check kernel/permissions" 6 52
    fi
    sleep 0.3
}

zram_disable() {
    safe_infobox "Disabling ZRAM..." 5 24
    swapoff /dev/zram0 2>/dev/null || true
    echo 1 > /sys/block/zram0/reset 2>/dev/null || true
    safe_msgbox "ZRAM disabled" 6 30
    sleep 0.2
}

ZRAMMenu() {
    while true; do
        local STATUS
        STATUS="$(get_zram_brief_status)"
        
        local CHOICE
        CHOICE=$(dialog --output-fd 1 \
            --backtitle "ZRAM Manager - ArkOS Manager by @lcdyk" \
            --title "ZRAM Manager" \
            --menu "Current ZRAM Status:\n$STATUS\n\nSelected Size: ${ZRAM_SIZE_BYTES} bytes" 18 60 8 \
            1 "Show detailed status" \
            2 "Set ZRAM size" \
            3 "Enable ZRAM" \
            4 "Disable ZRAM" \
            5 "Back" \
            2>"$CURR_TTY") || return
        
        case "$CHOICE" in
            1) zram_show_status ;;
            2) choose_zram_size ;;
            3) zram_enable ;;
            4) zram_disable ;;
            5) return ;;
            *) return ;;
        esac
    done
}

# ---------------------------------------------------------
# USB→WiFi Modeswitch (sysfs, no lsusb)
# ---------------------------------------------------------
list_usb_lines() {
    for devpath in /sys/bus/usb/devices/*; do
        [[ -d "$devpath" ]] || continue
        if [[ -r "$devpath/idVendor" && -r "$devpath/idProduct" ]]; then
            vid=$(tr -d '\n' < "$devpath/idVendor" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            pid=$(tr -d '\n' < "$devpath/idProduct" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            [[ -n "$vid" && -n "$pid" ]] || continue
            
            if [[ -r "$devpath/busnum" && -r "$devpath/devnum" ]]; then
                bus=$(printf "%03d" "$(cat "$devpath/busnum" 2>/dev/null)")
                dev=$(printf "%03d" "$(cat "$devpath/devnum" 2>/dev/null)")
                tag="${bus}-${dev}"
            else
                base="$(basename "$devpath")"
                tag="${base%%:*}"
            fi
            
            product="Unknown"
            [[ -r "$devpath/product" ]] && product=$(tr -d '\n' < "$devpath/product" 2>/dev/null || echo "Unknown")
            
            manuf=""
            [[ -r "$devpath/manufacturer" ]] && manuf=$(tr -d '\n' < "$devpath/manufacturer" 2>/dev/null || echo "")
            
            name="$product"
            [[ -n "$manuf" ]] && name="$manuf $product"
            
            echo "${tag}  ${vid}:${pid}  ${name}"
        fi
    done | sort
}

do_modeswitch() {
    local vidpid=$1
    local vid=${vidpid%%:*} pid=${vidpid##*:}
    
    safe_infobox "usb_modeswitch for $vidpid...\n(If device is in storage/CD mode, it should switch)" 6 64
    
    if [[ -f "/etc/usb_modeswitch.d/${vidpid}" ]]; then
        usb_modeswitch -c "/etc/usb_modeswitch.d/${vidpid}" >>/tmp/usb2wifi.log 2>&1 || true
    else
        usb_modeswitch -v 0x$vid -p 0x$pid \
            -M "5553424312345678000000000000061b000000020000000000000000000000" >>/tmp/usb2wifi.log 2>&1 || true
    fi
    
    sleep 2
    dmesg | tail -n 80 >>/tmp/usb2wifi.log
    safe_msgbox "Modeswitch triggered for $vidpid.\nIf VID:PID changes, re-plug or rescan." 8 66
}

persist_rule_path() {
    # $1: vid:pid (lowercase)
    echo "/etc/udev/rules.d/99-usb2wifi-$1.rules"
}

write_persist_cfg() {
    # $1: vid:pid (lowercase, "before switch" storage/CD mode ID)
    local vp="$1"
    local v="${vp%%:*}" p="${vp##*:}"
    local f="/etc/usb_modeswitch.d/$vp"
    local rule="$(persist_rule_path "$vp")"
    local usbm="$(command -v usb_modeswitch || echo /usr/sbin/usb_modeswitch)"
    
    # 1) Write usb_modeswitch config
    mkdir -p /etc/usb_modeswitch.d 2>/dev/null || true
    cat >"$f" <<EOF
# Auto-generated by ArkOS Manager
DefaultVendor=0x${v}
DefaultProduct=0x${p}
MessageContent="5553424312345678000000000000061b000000020000000000000000000000"
CheckSuccess=20
NeedResponse=1
EOF
    chmod 0644 "$f" 2>/dev/null || true
    
    # 2) Write udev rule for this VID:PID
    mkdir -p /etc/udev/rules.d 2>/dev/null || true
    cat >"$rule" <<EOF
# Auto-generated by ArkOS Manager (per-device rule)
ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", \\
  ATTR{idVendor}=="${v}", ATTR{idProduct}=="${p}", \\
  RUN+="${usbm} -c /etc/usb_modeswitch.d/${vp}"

ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}!="usb_device", \\
  ATTRS{idVendor}=="${v}", ATTRS{idProduct}=="${p}", \\
  RUN+="${usbm} -c /etc/usb_modeswitch.d/${vp}"
EOF
    chmod 0644 "$rule" 2>/dev/null || true
    
    # 3) Reload udev
    udevadm control --reload 2>/dev/null || true
}

persist_after_switch_prompt() {
    # $1: vid:pid (lowercase, "before switch" storage/CD mode ID)
    local vp="$1"
    local f="/etc/usb_modeswitch.d/$vp"
    
    if [[ -f "$f" ]]; then
        # Config already exists, ensure udev rule exists and reload
        write_persist_cfg "$vp"
        safe_msgbox "Persisted config already existed.\nUdev rule ensured & reloaded." 8 60
        return
    fi
    
    dialog --yesno "Persist switch config for $vp ?\nThis will:\n 1) Create /etc/usb_modeswitch.d/$vp\n 2) Add a local udev rule to auto-run usb_modeswitch on plug\nYou can remove it later in 'View/Delete persisted config'." 12 76 > "$CURR_TTY"
    if [[ $? -eq 0 ]]; then
        write_persist_cfg "$vp"
        safe_msgbox "Saved.\nNow re-plug the device to verify auto-switch." 8 60
    fi
}

show_or_delete_persist_cfg() {
    # $1: vid:pid (lowercase)
    local vp="$1"
    local f_cfg="/etc/usb_modeswitch.d/$vp"
    local f_rule
    f_rule="$(persist_rule_path "$vp")"
    
    local tmp="/tmp/usb2wifi_persist_${vp//:/_}.txt"
    {
        echo "VID:PID  = $vp"
        echo "CFG File = $f_cfg  ($( [[ -f "$f_cfg" ]] && echo 'present' || echo 'missing' ))"
        echo "Rule File= $f_rule ($( [[ -f "$f_rule" ]] && echo 'present' || echo 'missing' ))"
        echo
        echo "Tips:"
        echo " - CFG: /etc/usb_modeswitch.d/<vid:pid>   (modeswitch parameters)"
        echo " - Rule: /etc/udev/rules.d/99-usb2wifi-<vid:pid>.rules  (hotplug trigger)"
    } >"$tmp"
    
    while true; do
        local ch
        ch=$(dialog --output-fd 1 \
            --backtitle "USB→WiFi Modeswitch - ArkOS Manager" \
            --title "Persisted config for $vp" \
            --menu "Manage persisted files:\n\n$(sed -n '1,4p' "$tmp")" 18 80 10 \
            1 "View CFG file" \
            2 "View UDEV rule" \
            3 "Delete BOTH (CFG + Rule)" \
            4 "Delete only CFG" \
            5 "Delete only Rule" \
            6 "Back" 2>"$CURR_TTY") || return
        
        case "$ch" in
            1)
                if [[ -f "$f_cfg" ]]; then
                    safe_textbox "$f_cfg" 22 90
                else
                    safe_msgbox "CFG not found:\n$f_cfg" 8 60
                fi
                ;;
            2)
                if [[ -f "$f_rule" ]]; then
                    safe_textbox "$f_rule" 22 90
                else
                    safe_msgbox "Rule not found:\n$f_rule" 8 60
                fi
                ;;
            3)
                dialog --yesno "Delete BOTH files?\n\n$f_cfg\n$f_rule" 10 70 > "$CURR_TTY" || continue
                rm -f -- "$f_cfg" "$f_rule"
                udevadm control --reload 2>/dev/null || true
                safe_msgbox "Deleted both.\nUdev reloaded." 7 40
                return
                ;;
            4)
                dialog --yesno "Delete CFG only?\n\n$f_cfg" 8 70 > "$CURR_TTY" || continue
                rm -f -- "$f_cfg"
                safe_msgbox "CFG deleted." 6 24
                ;;
            5)
                dialog --yesno "Delete Rule only?\n\n$f_rule" 8 70 > "$CURR_TTY" || continue
                rm -f -- "$f_rule"
                udevadm control --reload 2>/dev/null || true
                safe_msgbox "Rule deleted.\nUdev reloaded." 7 40
                ;;
            6) return ;;
            *) return ;;
        esac
        
        # Update status
        {
            echo "VID:PID  = $vp"
            echo "CFG File = $f_cfg  ($( [[ -f "$f_cfg" ]] && echo 'present' || echo 'missing' ))"
            echo "Rule File= $f_rule ($( [[ -f "$f_rule" ]] && echo 'present' || echo 'missing' ))"
            echo
            echo "Tips:"
            echo " - CFG: /etc/usb_modeswitch.d/<vid:pid>   (modeswitch parameters)"
            echo " - Rule: /etc/udev/rules.d/99-usb2wifi-<vid:pid>.rules  (hotplug trigger)"
        } >"$tmp"
    done
}

USB2WiFiMenu() {
    local need=(dialog usb_modeswitch dmesg)
    local miss=0
    for c in "${need[@]}"; do
        command -v "$c" >/dev/null 2>&1 || { miss=1; }
    done
    
    if [[ $miss -eq 1 ]]; then
        safe_msgbox "Missing dependency for USB→WiFi Modeswitch:\n- usb_modeswitch\n- dmesg\nPlease install them first." 9 60
        return
    fi
    
    while true; do
        mapfile -t LINES < <(list_usb_lines)
        if [[ ${#LINES[@]} -eq 0 ]]; then
            safe_msgbox "No USB devices detected." 6 42
            return
        fi
        
        local MENU_OPTS=()
        local ln tag id name
        for ln in "${LINES[@]}"; do
            tag=$(awk '{print $1}' <<<"$ln")
            id=$(awk '{print $2}' <<<"$ln")
            name=$(cut -d' ' -f3- <<<"$ln")
            MENU_OPTS+=("$tag" "$id  $name")
        done
        MENU_OPTS+=("R" "Rescan USB list")
        MENU_OPTS+=("B" "Back")
        
        local CHOICE
        CHOICE=$(dialog --output-fd 1 \
            --backtitle "USB→WiFi Modeswitch - ArkOS Manager @lcdyk" \
            --title "Select a USB device" \
            --menu "" 22 90 14 "${MENU_OPTS[@]}" 2>"$CURR_TTY") || return
        
        case "$CHOICE" in
            B) return ;;
            R) continue ;;
            *)
                local sel_line sel_id sel_name
                sel_line="$(printf "%s\n" "${LINES[@]}" | awk -v t="$CHOICE" '$1==t{print; exit}')"
                sel_id=$(awk '{print $2}' <<<"$sel_line")
                sel_name=$(cut -d' ' -f3- <<<"$sel_line")
                
                while true; do
                    local CH
                    CH=$(dialog --output-fd 1 \
                        --backtitle "USB→WiFi Modeswitch - ArkOS Manager" \
                        --title "Device: $CHOICE  $sel_id" \
                        --menu "Name: $sel_name\nChoose action:" 14 72 7 \
                        1 "usb_modeswitch (try switch from storage/CD mode)" \
                        2 "View/Delete persisted config" \
                        3 "Back" 2>"$CURR_TTY") || break
                    
                    case "$CH" in
                        1)
                            do_modeswitch "$sel_id"
                            persist_after_switch_prompt "$sel_id"
                            ;;
                        2)
                            show_or_delete_persist_cfg "$sel_id"
                            ;;
                        3)
                            break
                            ;;
                        *)
                            break
                            ;;
                    esac
                done
                ;;
        esac
    done
}

# ---------------------------------------------------------
# Bluetooth Manager (BlueZ)
# ---------------------------------------------------------
bt_have_bluetoothctl() {
    command -v bluetoothctl >/dev/null 2>&1
}

bt_have_systemctl() {
    command -v systemctl >/dev/null 2>&1
}

bt_have_apt() {
    command -v apt-get >/dev/null 2>&1
}

bt_start_daemon() {
    if bt_have_systemctl; then
        systemctl enable bluetooth >/dev/null 2>&1 || true
        systemctl start bluetooth >/dev/null 2>&1 || true
        sleep 0.5
        if ! systemctl is-active --quiet bluetooth; then
            safe_infobox "bluetooth.service not active. Trying to spawn bluetoothd..." 6 60
            sleep 1
            if command -v bluetoothd >/dev/null 2>&1; then
                pkill -f "^bluetoothd" >/dev/null 2>&1 || true
                nohup bluetoothd >/dev/null 2>&1 &
                sleep 0.8
            fi
        fi
    else
        if command -v bluetoothd >/dev/null 2>&1; then
            pkill -f "^bluetoothd" >/dev/null 2>&1 || true
            nohup bluetoothd >/dev/null 2>&1 &
            sleep 0.8
        fi
    fi
}

bt_power_on() {
    rfkill unblock bluetooth 2>/dev/null || true
    bt_start_daemon
    
    if bt_have_bluetoothctl; then
        bluetoothctl <<'EOF' >/tmp/bt_on.log 2>&1
power on
agent on
default-agent
pairable on
discoverable on
discoverable-timeout 0
quit
EOF
        safe_msgbox "Bluetooth powered ON (pairable & discoverable)." 6 60
    else
        safe_msgbox "Bluetooth daemon started.\nInstall BlueZ to manage with bluetoothctl." 7 60
    fi
}

bt_power_off() {
    if bt_have_bluetoothctl; then
        bluetoothctl <<'EOF' >/tmp/bt_off.log 2>&1
power off
quit
EOF
    fi
    
    rfkill block bluetooth 2>/dev/null || true
    if bt_have_systemctl; then
        systemctl stop bluetooth >/dev/null 2>&1 || true
    else
        pkill -f "^bluetoothd" >/dev/null 2>&1 || true
    fi
    safe_msgbox "Bluetooth powered OFF." 6 35
}

bt_install_bluez() {
    if ! bt_have_apt; then
        safe_msgbox "apt-get not found. Cannot install BlueZ here." 7 50
        return
    fi
    
    safe_infobox "Installing BlueZ...\n(This needs internet)" 6 40
    DEBIAN_FRONTEND=noninteractive apt-get update >/tmp/bluez_install.log 2>&1 || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y bluez >>/tmp/bluez_install.log 2>&1 || true
    
    if bt_have_bluetoothctl; then
        safe_msgbox "BlueZ installed.\nbluetoothctl is available now." 7 45
    else
        safe_textbox "/tmp/bluez_install.log" 22 90
    fi
}

bt_scan_and_pair() {
    if ! bt_have_bluetoothctl; then
        dialog --msgbox "bluetoothctl not found.\nPlease install BlueZ first." 7 52 > "$CURR_TTY"
        return
    fi
    
    # Preset: power/agent/pairable; set scan parameters
    bluetoothctl <<'EOF' >/tmp/bt_prep.log 2>&1
power on
agent on
default-agent
pairable on
menu scan
transport auto
duplicate-data on
back
EOF
    
    # Start 20s scan, keep scan on in background (can refresh list later)
    dialog --infobox "Scanning Bluetooth devices for 20s..." 5 48 > "$CURR_TTY"
    { printf 'scan on\n'; sleep 20; } | bluetoothctl >/tmp/bt_scan.log 2>&1 &
    SCAN_PID=$!
    sleep 3
    
    # Helper function: read current known device list
    _bt_read_devices() {
        bluetoothctl devices 2>/dev/null | awk 'NF>=3 {mac=$2; sub("^Device "mac" ",""); name=$0; print mac"|"name}'
    }
    
    # Initial device list; if empty, wait and retry
    mapfile -t DEVLINES < <(_bt_read_devices)
    if [[ ${#DEVLINES[@]} -eq 0 ]]; then
        sleep 3
        mapfile -t DEVLINES < <(_bt_read_devices)
    fi
    
    # Menu loop: support Refresh/Rescan
    while true; do
        if [[ ${#DEVLINES[@]} -eq 0 ]]; then
            printf 'scan off\n' | bluetoothctl >/dev/null 2>&1 || true
            kill "$SCAN_PID" 2>/dev/null || true
            dialog --textbox "/tmp/bt_scan.log" 22 90
            dialog --msgbox "No devices found." 6 30 > "$CURR_TTY"
            return
        fi
        
        # Build menu items
        MENU_OPTS=()
        for ln in "${DEVLINES[@]}"; do
            mac="${ln%%|*}"
            name="${ln#*|}"
            [[ -z "$name" ]] && name="(no name)"
            MENU_OPTS+=("$mac" "$name")
        done
        MENU_OPTS+=("REFRESH" "Refresh list (keep scanning)")
        MENU_OPTS+=("RESCAN" "Rescan 20s (restart scan)")
        MENU_OPTS+=("BACK" "Back")
        
        SEL=$(dialog --output-fd 1 \
            --backtitle "Bluetooth Manager" \
            --title "Discovered devices" \
            --menu "Select a device to pair/connect" 22 72 14 \
            "${MENU_OPTS[@]}" 2>"$CURR_TTY") || {
            printf 'scan off\n' | bluetoothctl >/dev/null 2>&1
            kill "$SCAN_PID" 2>/dev/null || true
            return
        }
        
        case "$SEL" in
            BACK)
                printf 'scan off\n' | bluetoothctl >/dev/null 2>&1 || true
                kill "$SCAN_PID" 2>/dev/null || true
                return
                ;;
            REFRESH)
                mapfile -t DEVLINES < <(_bt_read_devices)
                continue
                ;;
            RESCAN)
                printf 'scan off\n' | bluetoothctl >/dev/null 2>&1 || true
                kill "$SCAN_PID" 2>/dev/null || true
                : > /tmp/bt_scan.log
                dialog --infobox "Rescanning for 20s..." 5 32 > "$CURR_TTY"
                { printf 'scan on\n'; sleep 20; } | bluetoothctl >>/tmp/bt_scan.log 2>&1 &
                SCAN_PID=$!
                sleep 3
                mapfile -t DEVLINES < <(_bt_read_devices)
                continue
                ;;
            *)
                # Selected a device
                bluetoothctl remove "$SEL" >/dev/null 2>&1 || true
                
                bt_wait_device_available() {
                    local mac="$1" timeout="${2:-12}" i
                    for ((i=0; i<timeout; i++)); do
                        if bluetoothctl devices | awk '{print $2}' | grep -iq "^${mac}$"; then
                            return 0
                        fi
                        sleep 1
                    done
                    return 1
                }
                
                # If not visible, force 8s scan and wait
                if ! bt_wait_device_available "$SEL" 12; then
                    { printf 'scan on\n'; sleep 8; } | bluetoothctl >/dev/null 2>&1
                    if ! bt_wait_device_available "$SEL" 8; then
                        dialog --msgbox "Device $SEL not available.\nPlease keep it in pairing mode and retry." 8 64 > "$CURR_TTY"
                        mapfile -t DEVLINES < <(_bt_read_devices)
                        continue
                    fi
                fi
                
                # Pair/trust/connect; keep scan on (some devices need scan window)
                : > /tmp/bt_pair_connect.log
                {
                    echo ">>> Pairing $SEL ..."
                    bluetoothctl pair "$SEL"
                    echo
                    echo ">>> Trusting $SEL ..."
                    bluetoothctl trust "$SEL"
                    echo
                    echo ">>> Connecting $SEL ..."
                    bluetoothctl connect "$SEL"
                    echo
                    echo ">>> Info:"
                    bluetoothctl info "$SEL"
                    echo
                } >>/tmp/bt_pair_connect.log 2>&1
                
                # Stop scan, show results
                printf 'scan off\n' | bluetoothctl >/dev/null 2>&1 || true
                kill "$SCAN_PID" 2>/dev/null || true
                dialog --textbox "/tmp/bt_pair_connect.log" 22 90 > "$CURR_TTY" || true
                
                if grep -qi "Pairing successful" /tmp/bt_pair_connect.log || grep -qi "Paired: yes" /tmp/bt_pair_connect.log; then
                    if grep -qi "Connection successful" /tmp/bt_pair_connect.log || grep -qi "Connected: yes" /tmp/bt_pair_connect.log; then
                        dialog --msgbox "Paired & Connected successfully." 6 40 > "$CURR_TTY"
                    else
                        dialog --msgbox "Paired successfully.\nIf not connected, try again or check profiles." 8 64 > "$CURR_TTY"
                    fi
                else
                    dialog --yesno "Pair/connect not completed.\nOpen interactive bluetoothctl now?" 8 60 > "$CURR_TTY"
                    if [[ $? -eq 0 ]]; then
                        printf "\033c" > "$CURR_TTY"
                        printf "Tips:\n power on\n agent on\n default-agent\n scan on\n pair <MAC>\n trust <MAC>\n connect <MAC>\n info <MAC>\n\nPress Ctrl+C to exit.\n\nLaunching bluetoothctl...\n" > "$CURR_TTY"
                        bluetoothctl </dev/tty1 >/dev/tty1 2>&1
                    fi
                fi
                return
                ;;
        esac
    done
}

BluetoothMenu() {
    while true; do
        local CH
        CH=$(dialog --output-fd 1 \
            --backtitle "Bluetooth Manager - ArkOS Manager" \
            --title "Bluetooth Manager" \
            --menu "Choose an action:" 16 60 8 \
            1 "Install BlueZ (needs internet)" \
            2 "Power ON Bluetooth" \
            3 "Scan & Pair Devices" \
            4 "Power OFF Bluetooth" \
            5 "Back" 2>"$CURR_TTY") || return
        
        case "$CH" in
            1) bt_install_bluez ;;
            2) bt_power_on ;;
            3) bt_scan_and_pair ;;
            4) bt_power_off ;;
            5) return ;;
            *) return ;;
        esac
    done
}

# ---------------------------------------------------------
# Exit / Main Menu
# ---------------------------------------------------------
ExitAll() {
    printf "\033c" > "$CURR_TTY"
    printf "\e[?25h" > "$CURR_TTY"   # show cursor
    pkill -f "gptokeyb -1 ArkManager.sh" 2>/dev/null || true
    exit 0
}

TopMenu() {
    while true; do
        local CH
        CH=$(dialog --output-fd 1 \
            --backtitle "ArkOS Manager by @lcdyk" \
            --title "ArkOS Manager" \
            --menu "Select a module:" 18 56 10 \
            1 "GPU Freq Manager" \
            2 "CPU Core Manager" \
            3 "ZRAM Manager" \
            4 "USB→WiFi Modeswitch" \
            5 "Bluetooth Manager" \
            6 "Exit" \
            2>"$CURR_TTY") || ExitAll
        
        case "$CH" in
            1) GPUMenu ;;
            2) CPUMenu ;;
            3) ZRAMMenu ;;
            4) USB2WiFiMenu ;;
            5) BluetoothMenu ;;
            6) ExitAll ;;
            *) ExitAll ;;
        esac
    done
}

# ---------------------------------------------------------
# Main Execution
# ---------------------------------------------------------
trap ExitAll EXIT SIGINT SIGTERM

# Gamepad key mapping
if command -v /opt/inttools/gptokeyb &> /dev/null; then
    [[ -e /dev/uinput ]] && chmod 666 /dev/uinput 2>/dev/null || true
    export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
    pkill -f "gptokeyb -1 ArkManager.sh" 2>/dev/null || true
    /opt/inttools/gptokeyb -1 "ArkManager.sh" -c "/opt/inttools/keys.gptk" >/dev/null 2>&1 &
else
    safe_infobox "gptokeyb not found. Joystick control disabled." 5 65
    sleep 2
fi

printf "\033c" > "$CURR_TTY"
TopMenu
