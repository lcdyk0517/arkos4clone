#!/bin/bash
# ES Status Daemon -- detects WiFi and Bluetooth state
# Writes state to /tmp/es-wifi-state and /tmp/es-bt-state
# WiFi states: 0=off 1=no-ip 2=connected 3=sharing-active 4=service-up
# BT states:   0=off 1=active-no-device 2=device-connected
#
# Optimized: reads /sys and /proc where possible to minimize fork+exec

detect_wifi() {
    # Check rfkill via /sys (no fork)
    if [ -f /sys/class/rfkill/rfkill0/soft ]; then
        # Find wifi rfkill device
        for dev in /sys/class/rfkill/*; do
            if [ -f "$dev/type" ] && [ "$(cat "$dev/type" 2>/dev/null)" = "wlan" ]; then
                [ "$(cat "$dev/soft" 2>/dev/null)" = "1" ] && echo 0 && return
                break
            fi
        done
    fi

    # Check wlan0 exists via /sys (no fork)
    [ -d /sys/class/net/wlan0 ] || { echo 0; return; }

    # Check carrier (connected to AP) via /sys (no fork)
    local carrier=$(cat /sys/class/net/wlan0/carrier 2>/dev/null)
    [ "$carrier" = "1" ] || { echo 1; return; }

    # Check if we have an IP address via /sys (no fork, just read file)
    local has_ip=$(cat /sys/class/net/wlan0/operstate 2>/dev/null)
    [ "$has_ip" = "up" ] || { echo 1; return; }

    # Check for sharing/service (needs ss, but only if connected)
    ss -tn state established 2>/dev/null | grep -qE ":(22|445|53) " && echo 3 && return

    # Check for running services (minimal forks)
    if pgrep -x "smbd\|nmbd\|sshd\|filebrowser" > /dev/null 2>&1; then
        echo 4 && return
    fi

    echo 2
}

detect_bt() {
    # Check rfkill via /sys (no fork)
    for dev in /sys/class/rfkill/*; do
        if [ -f "$dev/type" ] && [ "$(cat "$dev/type" 2>/dev/null)" = "bluetooth" ]; then
            [ "$(cat "$dev/soft" 2>/dev/null)" = "1" ] && echo 0 && return
            break
        fi
    done

    # Check hci device via /sys (no fork)
    [ -d /sys/class/bluetooth/hci0 ] || { echo 0; return; }

    # Check if bluetooth is powered via /sys (no fork)
    local powered=$(cat /sys/class/bluetooth/hci0/power 2>/dev/null)
    # Fallback: use bluetoothctl only if needed
    if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        echo 0 && return
    fi

    # Check connected devices (one fork)
    local conn=$(bluetoothctl info 2>/dev/null | grep -c "Connected: yes")
    [ "$conn" -gt 0 ] && echo 2 && return

    echo 1
}

while true; do
    wifi_val=$(detect_wifi)
    bt_val=$(detect_bt)
    echo "$wifi_val" > /tmp/es-wifi-state.tmp && mv /tmp/es-wifi-state.tmp /tmp/es-wifi-state
    echo "$bt_val"   > /tmp/es-bt-state.tmp   && mv /tmp/es-bt-state.tmp   /tmp/es-bt-state
    chmod 666 /tmp/es-wifi-state /tmp/es-bt-state 2>/dev/null
    sleep 5
done
