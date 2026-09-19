#!/bin/bash

if [[ -z ${@} ]]; then
  printf "\nNo valid argument provided such as pico8, retroarch or retroarch32\n\n"
  exit 1
fi

if [[ ${@} == "pico8" ]]; then
  filename="$2"
  ext="${filename##*.}"
  Directory=`grep pico-8 /etc/emulationstation/es_systems.cfg | head -1 | grep -oP '(?<path>/).*?(?=/pico-8)' | cut -c2-`
  if [[ ! -e /dev/shm/Splore_Loaded ]]; then
    Last_Game=`tac /${Directory}/pico-8/activity_log.txt | grep -m1 "${ext}" | grep -oP '(?<= /).*'`
    Last_Game_Name=`tac /${Directory}/pico-8/activity_log.txt | grep -m1 "${ext}" | grep -oP '(?<= /).*' | awk 'BEGIN {FS="/" } { print $4 }'`
    Last_Game_Name_Noext=`echo "$Last_Game_Name" | rev | cut -d"." -f2-8  | rev`
    if [ -f "/home/ark/.emulationstation/recovery/PICO-8/"$Last_Game_Name_Noext".xml" ]; then
      Last_Emulator=`sed -n "/$Last_Game_Name/{n;n;p}" /home/ark/.emulationstation/recovery/PICO-8/"$Last_Game_Name_Noext".xml | grep "<emulator>" |  grep -oP '(?<=>).*?(?=<)'`
    fi
    if [[ -z ${Last_Emulator} ]]; then
      Last_Emulator=`sed -n "/$Last_Game_Name/{n;n;p}" /${Directory}/pico-8/carts/gamelist.xml | grep "<emulator>" |  grep -oP '(?<=>).*?(?=<)'`
      if [[ -z ${Last_Emulator} ]]; then
        Last_Emulator=`grep PICO-8 /home/ark/.emulationstation/es_settings.cfg | grep -oP '(?<=PICO-8.emulator" value=").*?(?=")'`
          if [[ -z ${Last_Emulator} ]]; then
            Last_Emulator="float-scaled"
          fi
      fi
    fi

    echo "nice -n -19 /usr/local/bin/pico8.sh \"${Last_Emulator}\" \"/${Last_Game}\""
  else
    if [ -f "/home/ark/.emulationstation/recovery/PICO-8/zzzsplore.xml" ]; then
      Last_Emulator=`sed -n "/zzzsplore.p8/{n;n;p}" /home/ark/.emulationstation/recovery/PICO-8/zzzsplore.xml | grep "<emulator>" |  grep -oP '(?<=>).*?(?=<)'`
    fi
    if [[ -z ${Last_Emulator} ]]; then
      Last_Emulator=`sed -n "/zzzsplore.p8/{n;n;p}" /${Directory}/pico-8/carts/gamelist.xml | grep "<emulator>" |  grep -oP '(?<=>).*?(?=<)'`
      if [[ -z ${Last_Emulator} ]]; then
        Last_Emulator=`grep PICO-8 /home/ark/.emulationstation/es_settings.cfg | grep -oP '(?<=PICO-8.emulator" value=").*?(?=")'`
        if [[ -z ${Last_Emulator} ]]; then
          Last_Emulator="float-scaled"
        fi
      fi
    fi
    echo "nice -n -19 /usr/local/bin/pico8.sh \"${Last_Emulator}\" \"/${Directory}/pico-8/carts/zzzsplore.png\""
  fi
  exit 0
elif [[ -e /dev/shm/PNG_Loaded ]]; then
  if [[ -f /home/ark/.config/${@}/playlists/builtin/content_image_history.lpl ]]; then
    Last_Game=`grep '"path":' /home/ark/.config/${@}/builtin/content_image_history.lpl | head -1 | grep -oP '(?<=": ").*?(?=")'`
    Last_Core="/home/ark/.config/retroarch/cores/fake08_libretro.so"
  else
    Last_Game=`grep '"path":' /home/ark/.config/${@}/content_image_history.lpl | head -1 | grep -oP '(?<=": ").*?(?=")'`
    Last_Core="/home/ark/.config/retroarch/cores/fake08_libretro.so"
  fi
else
  if [[ -f /home/ark/.config/${@}/playlists/builtin/content_history.lpl ]]; then
    Last_Game=`grep '"path":' /home/ark/.config/${@}/playlists/builtin/content_history.lpl | head -1 | grep -oP '(?<=": ").*?(?=")'`
    Last_Core=`grep '"core_path":' /home/ark/.config/${@}/playlists/builtin/content_history.lpl | head -1 | grep -oP '(?<=": ").*?(?=")'`
  else
    Last_Game=`grep '"path":' /home/ark/.config/${@}/content_history.lpl | head -1 | grep -oP '(?<=": ").*?(?=")'`
    Last_Core=`grep '"core_path":' /home/ark/.config/${@}/content_history.lpl | head -1 | grep -oP '(?<=": ").*?(?=")'`
  fi
fi

echo "/usr/local/bin/BaRT_QuickMode.sh"

if [[ ${@} != "pico8" ]] && [[ ! -z $(pgrep quickmode.sh) ]]; then
  echo ". /usr/local/bin/buttonmon.sh"
  echo "Test_Button_R1"
  echo "if [ \"\$?\" -eq \"10\" ]; then"
  echo "  sudo systemctl start plymouth"
  echo "  sudo chmod 666 /dev/tty1"
  echo "  basefile=\"${Last_Game}\""
  echo "  basefilenoext=\"\${basefile%.*}\""
  echo "  printf \"\nAre you sure you want to delete the ${Last_Game} auto savestate?\n\" >> /dev/tty1"
  echo "  printf \"\nPress A to continue.  Press B to exit.\n\n\" >> /dev/tty1"
  echo "  while true"
  echo "  do"
  echo "      Test_Button_A"
  echo "      if [ \"\$?\" -eq \"10\" ]; then"
  echo "        printf \"\033[0mDeleteing the auto save state.  Please wait...\n\" >> /dev/tty1"
  echo "        sudo rm -fv \"\${basefilenoext}\".state.auto >> /dev/tty1"
  echo "        printf \"Done\n\" >> /dev/tty1"
  echo "        sleep 2"
  echo "        break"
  echo "      fi"
  echo ""
  echo "      Test_Button_B"
  echo "      if [ \"\$?\" -eq \"10\" ]; then"
  echo "        printf \"\033[0mSkipping the deletion of the auto save state of this game.\n\" >> /dev/tty1"
  echo "        sleep 2"
  echo "        break"
  echo "      fi"
  echo "  done"
  echo "fi"
  echo ""
fi

if [[ "$(tr -d '\0' < /proc/device-tree/compatible)" == *"rk3326"* ]]; then
  gpu="ff400000"
else
  gpu="fde60000"
fi

echo "sudo systemctl stop ondemand"
echo "sudo chmod 777 /sys/devices/platform/${gpu}.gpu/devfreq/${gpu}.gpu/governor"
echo "sudo chmod 777 /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
echo "sudo chmod 777 /sys/devices/platform/dmc/devfreq/dmc/governor"

mapfile settings < /dev/shm/governor_settings.state
echo "echo $(echo ${settings[0]}) | sudo tee /sys/devices/platform/${gpu}.gpu/devfreq/${gpu}.gpu/governor > /dev/null"
echo "echo $(echo ${settings[1]}) | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_governor > /dev/null"
echo "echo $(echo ${settings[2]}) | sudo tee /sys/devices/platform/dmc/devfreq/dmc/governor > /dev/null"
if [[ "$(cat /dev/shm/governor_settings.state)" == *"ondemand"* ]]; then
  echo "echo 85 | sudo tee -a /sys/devices/system/cpu/cpu*/cpufreq/ondemand/up_threshold > /dev/null"
  echo "echo 150 | sudo tee -a /sys/devices/system/cpu/cpu*/cpufreq/ondemand/sampling_down_factor > /dev/null"
fi
echo "cat /sys/devices/platform/${gpu}.gpu/devfreq/${gpu}.gpu/governor > /dev/shm/governor_settings.state"
echo "cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor >> /dev/shm/governor_settings.state"
echo "cat /sys/devices/platform/dmc/devfreq/dmc/governor >> /dev/shm/governor_settings.state"

if [[ "$(cat /dev/shm/governor_settings.state)" == *"userspace"* ]]; then
  if [ -f "/dev/shm/QBMODE" ]; then
    echo "echo $(cat /sys/devices/platform/${gpu}.gpu/devfreq/${gpu}.gpu/userspace/set_freq) | sudo tee /sys/devices/platform/${gpu}.gpu/devfreq/${gpu}.gpu/userspace/set_freq > /dev/null"
    echo "echo $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed) | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed > /dev/null"
    echo "echo $(cat /sys/devices/platform/dmc/devfreq/dmc/userspace/set_freq) | sudo tee /sys/devices/platform/dmc/devfreq/dmc/userspace/set_freq > /dev/null"
  else
    mapfile usettings < /dev/shm/userspace_speed_settings.state
    echo "echo $(echo ${usettings[0]}) | sudo tee /sys/devices/platform/${gpu}.gpu/devfreq/${gpu}.gpu/userspace/set_freq > /dev/null"
    echo "echo $(echo ${usettings[1]}) | sudo tee /sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed > /dev/null"
    echo "echo $(echo ${usettings[2]}) | sudo tee /sys/devices/platform/dmc/devfreq/dmc/userspace/set_freq > /dev/null"
    echo "cat /sys/devices/platform/${gpu}.gpu/devfreq/${gpu}.gpu/userspace/set_freq > /dev/shm/userspace_speed_settings.state"
    echo "cat /sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed >> /dev/shm/userspace_speed_settings.state"
    echo "cat /sys/devices/platform/dmc/devfreq/dmc/userspace/set_freq >> /dev/shm/userspace_speed_settings.state"
  fi
fi

echo "/usr/local/bin/${@} -L ${Last_Core} \"${Last_Game}\""

exit 0
