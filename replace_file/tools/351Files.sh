#!/bin/bash

cd /opt/351Files
export LD_LIBRARY_PATH="/opt/351Files/libs:$LD_LIBRARY_PATH"
if sudo -n true 2>/dev/null; then
    exec sudo -n -E env LD_LIBRARY_PATH="$DIR/libs:$LD_LIBRARY_PATH" "./351Files"
else
    exec "./351Files"
fi
printf "\033c" >> /dev/tty1
