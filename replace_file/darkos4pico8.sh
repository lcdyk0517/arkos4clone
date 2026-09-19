#!/bin/bash

res="480,320"
if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
  param_device="anbernic"
  if [ -f "/boot/rk3326-rg351v-linux.dtb" ]; then
    res="640,480"
  fi
elif [[ -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
  if [[ ! -z $(cat /etc/emulationstation/es_input.cfg | grep "190000004b4800000010000001010000") ]]; then
    param_device="oga"
  else
    param_device="rk2020"
  fi
elif [[ -e "/dev/input/by-path/platform-odroidgo3-joypad-event-joystick" ]]; then
  param_device="ogs"
  if [ -f "/boot/rk3326-rg351mp-linux.dtb" ] || [ -f "/boot/rk3326-g350-linux.dtb" ]; then
    res="640,480"
  else
    res="854,480"
  fi
elif [[ -e "/dev/input/by-path/platform-singleadc-joypad-event-joystick" ]]; then
  param_device="rg503"
  xres="$(cat /sys/class/graphics/fb0/modes | grep -o -P '(?<=:).*(?=p-)' | cut -dx -f1)"
  yres="$(cat /sys/class/graphics/fb0/modes | grep -o -P '(?<=:).*(?=p-)' | cut -dx -f2)"
  res="${xres},${yres}"
else
  param_device="chi"
  res="640,480"
fi

if [[ -f "/boot/.console" ]]; then
  CUR_VAL="$(tr -d '\r\n' < "/boot/.console" || true)"
  if [[ "$CUR_VAL" == "r36max" || "$CUR_VAL" == "xf40h" || "$CUR_VAL" == "dc40v" || "$CUR_VAL" == "r36ultra" || "$CUR_VAL" == "r36splus" || "$CUR_VAL" == "t16max" || "$CUR_VAL" == "r36tmax" || "$CUR_VAL" == "mini40" ]]; then
    res="720,720"
  elif [[ "$CUR_VAL" == "r46h" || "$CUR_VAL" == "r40xx" ]]; then
    res="1024,768"
  elif [[ "$CUR_VAL" == "u8" ]]; then
    res="800,480"
  elif [[ "$CUR_VAL" == "r50s" ]]; then
    res="854,480"
  elif [[ "$CUR_VAL" == "a10miniv4" ]]; then
    res="720,540"
  else
    res="640,480"
  fi
fi

directory="$(dirname "$2" | cut -d "/" -f2)"
basefile="$(basename -- "$2")"
basefilenoext="${basefile%.*}"

. /usr/local/bin/buttonmon.sh

if [[ ! -f "/$directory/pico-8/sdl_controllers.txt" ]]; then
echo "19000000030000000300000002030000,gameforce_gamepad,leftstick:b14,rightx:a3,leftshoulder:b4,start:b9,lefty:a0,dpup:b10,righty:a2,a:b1,b:b0,guide:b16,dpdown:b11,rightshoulder:b5,righttrigger:b7,rightstick:b15,dpright:b13,x:b2,back:b8,leftx:a1,y:b3,dpleft:b12,lefttrigger:b6,platform:Linux,
190000004b4800000010000000010000,GO-Advance Gamepad,a:b1,b:b0,x:b2,y:b3,leftshoulder:b4,rightshoulder:b5,dpdown:b7,dpleft:b8,dpright:b9,dpup:b6,leftx:a0,lefty:a1,guide:b10,leftstick:b12,lefttrigger:b11,rightstick:b13,righttrigger:b14,start:b15,platform:Linux,
190000004b4800000010000001010000,GO-Advance Gamepad (rev 1.1),a:b1,b:b0,x:b2,y:b3,leftshoulder:b4,rightshoulder:b5,dpdown:b9,dpleft:b10,dpright:b11,dpup:b8,leftx:a0,lefty:a1,guide:b12,leftstick:b14,lefttrigger:b13,rightstick:b15,righttrigger:b16,start:b17,platform:Linux,
190000004b4800000011000000010000,GO-Super Gamepad,x:b2,a:b1,b:b0,y:b3,back:b12,start:b13,dpleft:b10,dpdown:b9,dpright:b11,dpup:b8,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftstick:b14,rightstick:b15,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux,
03000000091200000031000011010000,OpenSimHardware OSH PB Controller,a:b1,b:b0,x:b2,y:b3,leftshoulder:b4,rightshoulder:b5,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b7,leftstick:b14,lefttrigger:b13,rightstick:b15,righttrigger:b16,leftx:a0~,lefty:a1~,start:b6,platform:Linux,
190000004b4800000111000000010000,retrogame_joypad,a:b1,b:b0,x:b2,y:b3,back:b8,start:b9,rightstick:b12,leftstick:b11,dpleft:b15,dpdown:b14,dpright:b16,dpup:b13,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux," > /$directory/pico-8/sdl_controllers.txt
fi

if [[ -f "/$directory/pico-8/pico8_64" ]]; then
  pico8executable=pico8_64
elif [[ -f "/$directory/pico-8/pico8_dyn" ]]; then
  pico8executable=pico8_dyn
elif [[ ! -z "$(find /$directory/pico-8/ -iname *raspi.zip)" ]]; then
  printf "\n Found $(find /$directory/pico-8/ -iname *raspi.zip).  Extracting the necessary" >> /dev/tty1
  printf "\n files.  Please wait..." >> /dev/tty1
  sleep 3
  unzip -jo "$(find /$directory/pico-8/ -iname *raspi.zip)" pico-8/pico8_64 pico-8/pico8.dat -d /$directory/pico-8/
  if [[ "$?" == "0" ]]; then
   printf "\n\nProcess completed successfully!" >> /dev/tty1
   sleep 3
   pico8executable=pico8_64
  else
   printf "\n\nProcess failed!  Please check the pico8 zip file and make sure it is not corrupted" >> /dev/tty1
   printf "\nand is an authentic file from lexaloffle you purchased!" >> /dev/tty1
   sleep 10
  fi
fi

LaunchFake08() {

  if [[ ! -f "/$directory/pico-8/fake08.gptk" ]]; then
    cp /opt/fake08/fake08.gptk /$directory/pico-8/fake08.gptk
  fi
  if [[ ${basefilenoext,,} == "zzzsplore" ]]; then
    printf "\033c" >> /dev/tty1
    printf "\033[1;33m" >> /dev/tty1
    printf "\n Sorry, splore is not available with the Fake08 emulator." >> /dev/tty1
    sleep 5
    printf "\033[0m" >> /dev/tty1
    printf "\033c" >> /dev/tty1
    exit 1
  fi


  if [[ ! -z $(cat /etc/emulationstation/es_input.cfg | grep "190000004b4800000010000001010000") ]] || [[ -e "/dev/input/by-path/platform-gameforce-gamepad-event-joystick" ]]; then
    export HOTKEY="l3"
  fi

  sudo chmod 666 /dev/uinput
  cd /opt/fake08

  sudo systemctl stop killer_daemon.service
  export FAKE08_HOME="/home/ark/.config"
  export FAKE08_PICO8DIR="/$directory/pico-8"
  export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
  /opt/inttools/gptokeyb -1 "fake08" -c "/$directory/pico-8/fake08.gptk" &
  ./fake08 "$1"
  unset SDL_GAMECONTROLLERCONFIG_FILE
  sudo kill -9 $(pidof gptokeyb)
  sudo systemctl restart ogage &
  printf "\033c" >> /dev/tty1
  exit 0
}

if [[ $1 == "retroarch" ]]; then
  if [[ ${basefilenoext,,} == "zzzsplore" ]]; then
    printf "\033c" >> /dev/tty1
    printf "\033[1;33m" >> /dev/tty1
    printf "\n Sorry, splore is not available with the Fake08 retroarch emulator." >> /dev/tty1
    sleep 5
    printf "\033[0m" >> /dev/tty1
    printf "\033c" >> /dev/tty1
    exit 1
  fi
  filename="$2"
  ext="${filename##*.}"
  if [[ "$ext" == "png" ]] || [[ "$ext" == "PNG" ]]; then
   sed -i '/builtin_imageviewer_enable \= "true"/c\builtin_imageviewer_enable \= "false"' /home/ark/.config/retroarch/retroarch.cfg
   /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/fake08_libretro.so "$2"
  else
    /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/fake08_libretro.so "$2"
  fi
  exit 0
fi

if [[ $1 == "fake08" ]]; then
      LaunchFake08 "$2"
elif [[ ! -f "/$directory/pico-8/$pico8executable" ]] && [[ "$1" != *"retroarch"* ]]; then
      printf "\033c" >> /dev/tty1
      printf "\033[1;33m" >> /dev/tty1
      msgbox "I don't detect a pico8_dyn or pico8_64 file in the /$directory/pico-8 folder. \
      Please place your purchased pico-8 files in this location and try to launch your cart \
      again. For now, this game will be launched using the Fake08 emulator. Press A to continue."
      printf "\033[0m" >> /dev/tty1
      LaunchFake08 "$2"
elif [[ ! -f "/$directory/pico-8/pico8.dat" ]] &&  [[ "$1" != *"retroarch"* ]]; then
      printf "\033c" >> /dev/tty1
      printf "\033[1;33m" >> /dev/tty1
      msgbox "I don't detect a pico8.dat file in the /$directory/pico-8 folder. Please place \
      your purchased pico-8 files in this location and try to launch your cart again. For now, \
      this game will be launched using the Fake08 emulator. Press A to continue."
      printf "\033[0m" >> /dev/tty1
      LaunchFake08 "$2"
fi

echo "VAR=$pico8executable" > /home/ark/.config/KILLIT
sudo systemctl restart killer_daemon.service

if [ ! -d "/opt/pico-8/bbs" ]; then
  mkdir -p /opt/pico-8/bbs
fi

unlink /opt/pico-8/bbs/carts
if [[ "/opt/pico-8/carts" == "$(realpath --canonicalize-existing /opt/pico-8/carts)" ]]; then
  rm -rf /opt/pico-8/carts
fi
unlink /opt/pico-8/carts
ln -sf /$directory/pico-8/favourites.txt /opt/pico-8/favourites.txt
ln -sf /$directory/pico-8/sdl_controllers.txt /opt/pico-8/sdl_controllers.txt
ln -sf /$directory/pico-8/carts /opt/pico-8/bbs/carts
ln -sf /$directory/pico-8/carts /opt/pico-8/carts

Test_Button_B
if [ "$?" -eq "10" ]; then
  printf "\n Starting splore.  Please wait..." >> /dev/tty1
  touch /dev/shm/Splore_Loaded
  if [[ $1 == "float-scaled" ]]; then
    /$directory/pico-8/$pico8executable -splore -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0
  elif [[ $1 == "pixel-perfect" ]]; then
    /$directory/pico-8/$pico8executable -splore -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0 -pixel_perfect 1
  elif [[ $1 == "full-screen" ]]; then
    /$directory/pico-8/$pico8executable -splore -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0 -draw_rect 0,0,$res
  fi
  rm /dev/shm/Splore_Loaded

  printf "\033[0m" >> /dev/tty1
   #mv -f /$directory/pico-8/bbs/carts/*.png /$directory/pico-8/carts/
   #mv -f /$directory/pico-8/bbs/carts/*.PNG /$directory/pico-8/carts/
   #mv -f /$directory/pico-8/bbs/carts/*.p8 /$directory/pico-8/carts/
   #mv -f /$directory/pico-8/bbs/carts/*.P8 /$directory/pico-8/carts/

  sudo systemctl stop killer_daemon.service
  sudo systemctl restart ogage &
  exit 0
fi

if [[ $1 == "float-scaled" ]]; then
	if [[ ${basefilenoext,,} == "zzzsplore" ]]; then
		touch /dev/shm/Splore_Loaded
		/$directory/pico-8/$pico8executable -splore -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0
		rm /dev/shm/Splore_Loaded
	else
		/$directory/pico-8/$pico8executable -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0 -run "$2"
	fi
elif [[ $1 == "pixel-perfect" ]]; then
	if [[ ${basefilenoext,,} == "zzzsplore" ]]; then
		touch /dev/shm/Splore_Loaded
		/$directory/pico-8/$pico8executable -splore -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0 -pixel_perfect 1
		rm /dev/shm/Splore_Loaded
	else
		/$directory/pico-8/$pico8executable -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0 -pixel_perfect 1 -run "$2"
	fi
elif [[ $1 == "full-screen" ]]; then
	if [[ ${basefilenoext,,} == "zzzsplore" ]]; then
		touch /dev/shm/Splore_Loaded
		/$directory/pico-8/$pico8executable -splore -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0 -draw_rect 0,0,$res
		rm /dev/shm/Splore_Loaded
	else
		/$directory/pico-8/$pico8executable -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0 -draw_rect 0,0,$res -run "$2"
	fi
fi

sudo systemctl stop killer_daemon.service
sudo systemctl restart ogage &
