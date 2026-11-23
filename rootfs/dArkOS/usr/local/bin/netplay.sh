#!/bin/bash
# Netplay lobby browser entry (dArkOS: Settings -> Online tools -> Netplay).
# Controller mapping is passed through SDL, not hard-coded in the binary.
# ZeroTier is started on demand; stop it from the same menu.
if [ -r /opt/inttools/gamecontrollerdb.txt ]; then
  export SDL_GAMECONTROLLERCONFIG_FILE="${SDL_GAMECONTROLLERCONFIG_FILE:-/opt/inttools/gamecontrollerdb.txt}"
fi
printf "\033c" > /dev/tty1
exec /opt/online-tool/netplay "$@"
