#!/bin/bash
# ============================================================
#  zram-setup.sh
#  Setup/teardown zram swap based on /etc/zram.conf
#  Usage: zram-setup.sh start|stop
# ============================================================

CONF="/etc/zram.conf"

# Default values
ENABLED=1
ALGORITHM="lz4"
SIZE=536870912  # 512M

# Read config if it exists
if [ -f "$CONF" ]; then
    . "$CONF"
fi

case "$1" in
    start)
        if [ "$ENABLED" != "1" ]; then
            exit 0
        fi

        # Disable if already active
        swapoff /dev/zram0 2>/dev/null || true

        # Reset zram device
        echo 1 > /sys/block/zram0/reset 2>/dev/null || true

        # Set compression algorithm (must be after reset, before disksize)
        if [ -n "$ALGORITHM" ]; then
            echo "$ALGORITHM" > /sys/block/zram0/comp_algorithm 2>/dev/null || true
        fi

        # Set disk size
        echo "$SIZE" > /sys/block/zram0/disksize 2>/dev/null || true

        # Create swap and enable
        mkswap /dev/zram0 >/dev/null 2>&1
        swapon -p 5 /dev/zram0 >/dev/null 2>&1
        ;;
    stop)
        swapoff /dev/zram0 2>/dev/null || true
        echo 1 > /sys/block/zram0/reset 2>/dev/null || true
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0
