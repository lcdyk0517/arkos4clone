#!/bin/bash

param_device="ogs"
output=$(/usr/local/bin/console_detect -r)
xres=$(echo "$output" | cut -d'x' -f1)
yres=$(echo "$output" | cut -d'x' -f2)
res="${xres},${yres}"

directory="$(dirname "$2" | cut -d "/" -f2)"
basefile="$(basename -- "$2")"
basefilenoext="${basefile%.*}"

. /usr/local/bin/buttonmon.sh

if [[ ! -f "/$directory/pico-8/sdl_controllers.txt" ]]; then
	echo "190000004b4800000011000000010000,GO-Super Gamepad,x:b2,a:b1,b:b0,y:b3,back:b12,start:b13,dpleft:b10,dpdown:b9,dpright:b11,dpup:b8,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftstick:b14,rightstick:b15,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux," >/$directory/pico-8/sdl_controllers.txt
fi

if [[ -f "/$directory/pico-8/pico8_64" ]]; then
	pico8executable=pico8_64
elif [[ -f "/$directory/pico-8/pico8_dyn" ]]; then
	pico8executable=pico8_dyn
fi

LaunchFake08() {
	if [[ ! -f "/$directory/pico-8/fake08.gptk" ]]; then
		cp /opt/fake08/fake08.gptk /$directory/pico-8/fake08.gptk
	fi
	if [[ ${basefilenoext,,} == "zzzsplore" ]]; then
		printf "\033c" >>/dev/tty1
		printf "\033[1;33m" >>/dev/tty1
		printf "\n Sorry, splore is not available with the Fake08 emulator." >>/dev/tty1
		sleep 5
		printf "\033[0m" >>/dev/tty1
		printf "\033c" >>/dev/tty1
		exit 1
	fi

	sudo chmod 666 /dev/uinput
	cd /opt/fake08

	sudo systemctl stop pico8hotkey
	export FAKE08_HOME="/home/ark/.config"
	export FAKE08_PICO8DIR="/$directory/pico-8"
	export SDL_GAMECONTROLLERCONFIG_FILE="./gamecontrollerdb.txt"
	./gptokeyb -1 "fake08" -c "/$directory/pico-8/fake08.gptk" &
	./fake08 "$1"
	unset SDL_GAMECONTROLLERCONFIG_FILE
	sudo kill -9 $(pidof gptokeyb)
	sudo systemctl restart oga_events &
	printf "\033c" >>/dev/tty1
	exit 0
}

if [[ $1 == "retroarch" ]]; then
	if [[ ${basefilenoext,,} == "zzzsplore" ]]; then
		printf "\033c" >>/dev/tty1
		printf "\033[1;33m" >>/dev/tty1
		printf "\n Sorry, splore is not available with the Fake08 retroarch emulator." >>/dev/tty1
		sleep 5
		printf "\033[0m" >>/dev/tty1
		printf "\033c" >>/dev/tty1
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
	printf "\033c" >>/dev/tty1
	printf "\033[1;33m" >>/dev/tty1
	msgbox "I don't detect a pico8_dyn or pico8_64 file in the /$directory/pico-8 folder. \
      Please place your purchased pico-8 files in this location and try to launch your cart \
      again. For now, this game will be launched using the Fake08 emulator. Press A to continue."
	printf "\033[0m" >>/dev/tty1
	LaunchFake08 "$2"
elif [[ ! -f "/$directory/pico-8/pico8.dat" ]] && [[ "$1" != *"retroarch"* ]]; then
	printf "\033c" >>/dev/tty1
	printf "\033[1;33m" >>/dev/tty1
	msgbox "I don't detect a pico8.dat file in the /$directory/pico-8 folder. Please place \
      your purchased pico-8 files in this location and try to launch your cart again. For now, \
      this game will be launched using the Fake08 emulator. Press A to continue."
	printf "\033[0m" >>/dev/tty1
	LaunchFake08 "$2"
fi

sudo /opt/quitter/oga_controls $pico8executable $param_device &

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
	printf "\n Starting splore.  Please wait..." >>/dev/tty1
	touch /dev/shm/Splore_Loaded
	if [[ $1 == "float-scaled" ]]; then
		/$directory/pico-8/$pico8executable -splore -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0
	elif [[ $1 == "pixel-perfect" ]]; then
		/$directory/pico-8/$pico8executable -splore -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0 -pixel_perfect 1
	elif [[ $1 == "full-screen" ]]; then
		/$directory/pico-8/$pico8executable -splore -home /opt/pico-8/ -root_path /$directory/pico-8/carts/ -joystick 0 -draw_rect 0,0,$res
	fi
	rm /dev/shm/Splore_Loaded

	printf "\033[0m" >>/dev/tty1

	if [[ ! -z $(pidof oga_controls) ]]; then
		sudo kill -9 $(pidof oga_controls)
	fi
	sudo systemctl restart oga_events &
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

if [[ ! -z $(pidof oga_controls) ]]; then
	sudo kill -9 $(pidof oga_controls)
fi
sudo systemctl restart oga_events &
