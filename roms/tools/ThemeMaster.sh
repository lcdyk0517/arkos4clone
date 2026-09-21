#!/bin/bash
#
# ThemeMaster
# https://github.com/JohnIrvine1433/ThemeMaster
# Description : launch script
#
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/ThemeMaster"
chmod +x ./ThemeMaster
chmod +x ./tm-joypad
chmod +x ./tm-viewer
echo "$(date)" > ./ThemeMaster.log
if [ "${UI_SERVICE}" = "weston.service" ]; then
  run './ThemeMaster 2>&1 | tee -a ./ThemeMaster.log'
elif [ "${UI_SERVICE}" = "sway.service essway.service" ]; then
  foot -F ./ThemeMaster 2>&1 | tee -a ./ThemeMaster.log
else
  bash ./ThemeMaster 2>&1 | tee -a ./ThemeMaster.log
fi
