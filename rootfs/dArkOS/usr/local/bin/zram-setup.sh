#!/bin/bash
# ============================================================
#  zram-setup.sh
#  Setup/teardown zram swap based on /etc/zram.conf
#  Usage: zram-setup.sh start|stop
# ============================================================

CONF="/etc/zram.conf"
# mkswap, swapon and swapoff are in /usr/sbin; sudo keeps the caller's PATH here
export PATH="/usr/sbin:/sbin:$PATH"

# Default values
ENABLED=1
ALGORITHM="zstd"
SIZE=1073741824  # 1024M

# Read config if it exists. Older EmulationStation builds wrote it with
# "echo -e" through /bin/sh, which leaves a literal "-e " on the first line.
if [ -f "$CONF" ]; then
    eval "$(sed 's/^-e //' "$CONF")"
fi

# Use the configured algorithm if this kernel has it, else the first one it
# has from this list (the 4.4 kernel only has lzo).
pick_algorithm() {
    local have a
    have=" $(tr -d '[]' < /sys/block/zram0/comp_algorithm 2>/dev/null) "
    for a in "$ALGORITHM" zstd lz4 lzo-rle lzo; do
        case "$have" in *" $a "*) echo "$a"; return ;; esac
    done
}

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
        ALGORITHM=$(pick_algorithm)
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
