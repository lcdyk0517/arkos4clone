directory="$(dirname "$1" | cut -d "/" -f2)"
# The DSperate standalone emulator does not support 7z archive files.  We'll take care of that here
game="$1"
ext="${1##*.}"
if [[ "${ext,,}" == "7z" ]]; then
    if [ ! -d "/dev/shm/ndsroms" ]; then
        mkdir -p /dev/shm/ndsroms
    else
        rm -rf /dev/shm/ndsroms/*
    fi
    # game variable will be updated with the file that is found in the 7z archive
    ROM="$game"
    7z e "$ROM" -bd -aoa -o/dev/shm/ndsroms/

    if [ $? != 0 ]; then
        printf "\nCouldn't decompress $ROM\nSomething seems to be wrong with this archive." > /dev/tty1
        sleep 5
        printf "\033c" > /dev/tty1
        exit 1
    fi

    for CART in nds NDS; do
        game=`find /dev/shm/ndsroms/ -iname "*.${CART}" | tac | head -n 1`
        if [ ! -z "$game" ]; then
        break;
        fi
    done
    if [ -z "$game" ]; then
        printf "\nCouldn't find a compatible rom of type .nds or .NDS in $ROM\n" > /dev/tty1
        sleep 5
        printf "\033c" > /dev/tty1
        exit 1
    fi
fi

if [[ ! -d "/${directory}/nds/dsperate" ]]; then
    mkdir /${directory}/nds/dsperate
    cp /opt/DSperate/config/dsperate.ini /${directory}/nds/dsperate/.
fi

if [[ ! -s "/${directory}/nds/dsperate/dsperate.ini" ]]; then
    cp /opt/DSperate/config/dsperate.ini /${directory}/nds/dsperate/.
fi

ln -sfn /${directory}/nds/dsperate /home/ark/.config/

if [[ ! -d "/${directory}/nds/cheats" ]]; then
    mkdir /${directory}/nds/cheats
fi

if [[ ! -d "/${directory}/nds/savestates" ]]; then
    mkdir /${directory}/nds/savestates
fi

sed -i "/saves =/c\saves = /${directory}/nds" /${directory}/nds/dsperate/dsperate.ini
sed -i "/states =/c\states = /${directory}/nds/savestates" /${directory}/nds/dsperate/dsperate.ini
sed -i "/cheats =/c\cheats = /${directory}/nds/cheats" /${directory}/nds/dsperate/dsperate.ini

sdl_controllerconfig="190000004b4800000011000000010000,GO-Super Gamepad,x:b2,a:b1,b:b0,y:b3,back:b12,start:b13,dpleft:b10,dpdown:b9,dpright:b11,dpup:b8,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftstick:b14,rightstick:b15,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux,"
SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" /opt/DSperate/dsperate "$game" --bios9 /${directory}/bios/nds_bios9.bin --bios7 /${directory}/bios/nds_bios7.bin --firmware /${directory}/bios/nds_firmware.bin

if [ -d "/dev/shm/ndsroms" ]; then
rm -rf /dev/shm/ndsroms
fi