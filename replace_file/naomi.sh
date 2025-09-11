#!/bin/bash

ESUDO=""

if  [[ $1 == "retroarch" ]]; then
/usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2"_libretro.so "$3"
elif [[ $1 == "retroarch32" ]]; then
/usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2"_libretro.so "$3"
elif [[ $1 == "standalone" ]]; then
  if [ ! -f  "/usr/local/bin/flycastsakeydemon.py" ]; then
    sudo cp -fv /usr/local/bin/ti99keydemon.py /usr/local/bin/flycastsakeydemon.py
    sudo chmod 777 /usr/local/bin/flycastsakeydemon.py
    sudo sed -i 's/pkill ti99sim-sdl/sudo kill -9 \$(pidof flycast)/' /usr/local/bin/flycastsakeydemon.py
  fi
sudo /usr/local/bin/flycastsakeydemon.py &
rm -rf "/home/ark/.local/share/flycast"
directory=$(dirname "$2" | cut -d "/" -f2)
ln -sf "/$directory/bios/dc" "/home/ark/.local/share/flycast"
if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
  sdl_controllerconfig="03000000091200000031000011010000,OpenSimHardware OSH PB Controller,a:b0,b:b1,x:b2,y:b3,leftshoulder:b4,rightshoulder:b5,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,leftx:a0~,lefty:a1~,leftstick:b8,lefttrigger:b10,rightstick:b9,back:b7,start:b6,rightx:a2,righty:a3,righttrigger:b11,platform:Linux,"
elif [[ -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
  if [[ ! -z $(cat /etc/emulationstation/es_input.cfg | grep "190000004b4800000010000001010000") ]]; then
    sdl_controllerconfig="190000004b4800000010000001010000,GO-Advance Gamepad (rev 1.1),a:b0,b:b1,x:b3,y:b2,leftshoulder:b4,rightshoulder:b5,dpdown:b9,dpleft:b10,dpright:b11,dpup:b8,leftx:a0,lefty:a1,back:b12,leftstick:b13,lefttrigger:b14,rightstick:b16,righttrigger:b15,start:b17,platform:Linux,"
  else
    sdl_controllerconfig="190000004b4800000010000000010000,GO-Advance Gamepad,a:b0,b:b1,x:b3,y:b2,leftshoulder:b4,rightshoulder:b5,dpdown:b7,dpleft:b8,dpright:b9,dpup:b6,leftx:a0,lefty:a1,back:b10,lefttrigger:b12,righttrigger:b13,start:b15,platform:Linux,"
  fi
elif [[ -e "/dev/input/by-path/platform-odroidgo3-joypad-event-joystick" ]]; then
  sdl_controllerconfig="190000004b4800000011000000010000,GO-Super Gamepad,x:b3,a:b0,b:b1,y:b2,back:b12,start:b13,dpleft:b10,dpdown:b9,dpright:b11,dpup:b8,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftstick:b14,rightstick:b15,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux,"
elif [[ -e "/dev/input/by-path/platform-singleadc-joypad-event-joystick" ]]; then
  sdl_controllerconfig="190000004b4800000111000000010000,retrogame_joypad,a:b0,b:b1,x:b3,y:b2,back:b8,start:b9,rightstick:b12,leftstick:b11,dpleft:b15,dpdown:b14,dpright:b16,dpup:b13,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux,"
else
  sdl_controllerconfig="19000000030000000300000002030000,gameforce_gamepad,leftstick:b14,rightx:a3,leftshoulder:b4,start:b9,lefty:a0,dpup:b10,righty:a2,a:b0,b:b1,guide:b16,dpdown:b11,rightshoulder:b5,righttrigger:b7,rightstick:b15,dpright:b13,x:b3,back:b8,leftx:a1,y:b2,dpleft:b12,lefttrigger:b6,platform:Linux,"
fi
LD_LIBRARY_PATH=/opt/flycastsa/libs/ SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" /opt/flycastsa/flycast "$2"
sudo killall python3
sudo systemctl restart oga_events &
elif [[ $1 == "retrorun" ]]; then
if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
  #sudo rm /dev/input/by-path/platform-odroidgo2-joypad-event-joystick || true
  #echo 'creating fake joypad'
  #sudo /usr/local/bin/rg351p-js2xbox --silent -t oga_joypad &
  #sleep 0.2
  #sudo ln -s /dev/input/event4 /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
  #sudo chmod 777 /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
  #sleep 0.2
  ESUDO="sudo --preserve-env=DEVICE_NAME"
  DEVICENAME="RG351V"
elif [ -f "/boot/rk3566.dtb" ] || [ -f "/boot/rk3566-OC.dtb" ]; then
  if test ! -z "$(grep "RG353V" /home/ark/.config/.DEVICE | tr -d '\0')"
  then
    DEVICENAME="RG353V"
  elif test ! -z "$(grep "RG353M" /home/ark/.config/.DEVICE | tr -d '\0')"
  then
    DEVICENAME="RG353M"
  else
    DEVICENAME="RG503"
  fi
elif [ -f "/boot/rk3326-r33s-linux.dtb" ] || [ -f "/boot/rk3326-r35s-linux.dtb" ] || [ -f "/boot/rk3326-r36s-linux.dtb" ] || [ -f "/boot/rk3326-rg351mp-linux.dtb" ]; then
DEVICENAME="RG351MP"
elif [ -f "/boot/rk3326-gameforce-linux.dtb" ]; then
DEVICENAME="RG351MP"
elif [ -f "/boot/rk3326-odroidgo2-linux.dtb" ] || [ -f "/boot/rk3326-odroidgo2-linux-v11.dtb" ] || [ -f "/boot/rk3326-odroidgo3-linux.dtb" ]; then
DEVICENAME="RGB10"
elif [ -f "/boot/rk3326-r36max-linux.dtb" ] || [ -f "/boot/rk3326-r36ultra-linux.dtb" ] || [ -f "/boot/rk3326-xf40h-linux.dtb" ] || [ -f "/boot/rk3326-xf40v-linux.dtb" ] || [ -f "/boot/rk3326-dc40v-linux.dtb" ]; then
DEVICENAME="RG351MP"
else
DEVICENAME="RG351P"
fi
export DEVICE_NAME="${DEVICENAME}"

#CURRUMBLESET="$(grep "retrorun_rumble_type = " /home/ark/.config/retrorun.cfg | cut -c24-)"

#if [[ ${DEVICENAME} == "RG503" ]]; then
  #if [[ ${CURRUMBLESET} != "event" ]]; then
    #sed -i "/retrorun_rumble_type \=/c\retrorun_rumble_type \= event" /home/ark/.config/retrorun.cfg
  #fi
#else
  #if [[ ${CURRUMBLESET} != "pwm" ]]; then
    #sed -i "/retrorun_rumble_type \=/c\retrorun_rumble_type \= pwm" /home/ark/.config/retrorun.cfg
  #fi
#fi

directory=$(dirname "$3" | cut -d "/" -f2)
CURDIRECTORYSET="$(grep "retrorun_screenshot_folder = " /home/ark/.config/retrorun.cfg | cut -d "/" -f2-3)"
if [[ "${CURDIRECTORYSET}" != "${directory}/naomi" ]]; then
  sed -i "/retrorun_screenshot_folder \=/c\retrorun_screenshot_folder \= \/$directory\/naomi" /home/ark/.config/retrorun.cfg
fi
$ESUDO /usr/local/bin/retrorun -c /home/ark/.config/retrorun.cfg --triggers -s /$directory/naomi -d /$directory/bios /home/ark/.config/retroarch/cores/"$2"_libretro.so "$3"

#if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
  #sleep 0.5
  #sudo rm /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
  #sudo kill $(pidof rg351p-js2xbox)
#fi
printf "\033c" >> /dev/tty1
else
if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
  #sudo rm /dev/input/by-path/platform-odroidgo2-joypad-event-joystick || true
  #echo 'creating fake joypad'
  #sudo /usr/local/bin/rg351p-js2xbox --silent -t oga_joypad &
  #sleep 0.2
  #sudo ln -s /dev/input/event4 /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
  #sudo chmod 777 /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
  #sleep 0.2
  ESUDO="sudo --preserve-env=DEVICE_NAME"
  DEVICENAME="RG351V"
elif [ -f "/boot/rk3566.dtb" ] || [ -f "/boot/rk3566-OC.dtb" ]; then
  if test ! -z "$(grep "RG353V" /home/ark/.config/.DEVICE | tr -d '\0')"
  then
    DEVICENAME="RG353V"
  elif test ! -z "$(grep "RG353M" /home/ark/.config/.DEVICE | tr -d '\0')"
  then
    DEVICENAME="RG353M"
  else
    DEVICENAME="RG503"
  fi
elif [ -f "/boot/rk3326-r33s-linux.dtb" ] || [ -f "/boot/rk3326-r35s-linux.dtb" ] || [ -f "/boot/rk3326-r36s-linux.dtb" ] || [ -f "/boot/rk3326-rg351mp-linux.dtb" ]; then
DEVICENAME="RG351MP"
elif [ -f "/boot/rk3326-gameforce-linux.dtb" ]; then
DEVICENAME="RG351MP"
elif [ -f "/boot/rk3326-odroidgo2-linux.dtb" ] || [ -f "/boot/rk3326-odroidgo2-linux-v11.dtb" ] || [ -f "/boot/rk3326-odroidgo3-linux.dtb" ]; then
DEVICENAME="RGB10"
elif [ -f "/boot/rk3326-r36max-linux.dtb" ] || [ -f "/boot/rk3326-r36ultra-linux.dtb" ] || [ -f "/boot/rk3326-xf40h-linux.dtb" ] || [ -f "/boot/rk3326-xf40v-linux.dtb" ] || [ -f "/boot/rk3326-dc40v-linux.dtb" ]; then
DEVICENAME="RG351MP"
else
DEVICENAME="RG351P"
fi
export DEVICE_NAME="${DEVICENAME}"

#CURRUMBLESET="$(grep "retrorun_rumble_type = " /home/ark/.config/retrorun.cfg | cut -c24-)"

#if [[ ${DEVICENAME} == "RG503" ]]; then
  #if [[ ${CURRUMBLESET} != "event" ]]; then
    #sed -i "/retrorun_rumble_type \=/c\retrorun_rumble_type \= event" /home/ark/.config/retrorun.cfg
  #fi
#else
  #if [[ ${CURRUMBLESET} != "pwm" ]]; then
    #sed -i "/retrorun_rumble_type \=/c\retrorun_rumble_type \= pwm" /home/ark/.config/retrorun.cfg
  #fi
#fi

directory=$(dirname "$3" | cut -d "/" -f2)
CURDIRECTORYSET="$(grep "retrorun_screenshot_folder = " /home/ark/.config/retrorun.cfg | cut -d "/" -f2-3)"
if [[ "${CURDIRECTORYSET}" != "${directory}/naomi" ]]; then
  sed -i "/retrorun_screenshot_folder \=/c\retrorun_screenshot_folder \= \/$directory\/naomi" /home/ark/.config/retrorun.cfg
fi

$ESUDO /usr/local/bin/retrorun32 -c /home/ark/.config/retrorun.cfg --triggers -s /$directory/naomi -d /$directory/bios /home/ark/.config/retroarch32/cores/"$2"_libretro.so "$3"

#if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
  #sleep 0.5
  #sudo rm /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
  #sudo kill $(pidof rg351p-js2xbox)
#fi
printf "\033c" >> /dev/tty1
fi
