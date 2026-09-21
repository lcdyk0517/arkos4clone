#!/bin/bash

################################################################################################
# Thanks to stupidhoroscope for the breakdown on how this is achieved in OnionOS               #
################################################################################################

. /usr/local/bin/buttonmon.sh

printf "\nAre you sure you want to disable Quick Mode?"
printf "\nPress A to continue.  Press B to exit.\n"

while true
do
   Test_Button_A
   if [ "$?" -eq "10" ]; then
	# First let's disable retroarch and retroarch32 to autosaves and autoload savestates on game launch
	printf "Disabling Quick Mode. Please wait..."
	sed -i '/savestate_auto_save \=/c\savestate_auto_save \= \"false\"' /home/ark/.config/retroarch/retroarch.cfg
	sed -i '/savestate_auto_save \=/c\savestate_auto_save \= \"false\"' /home/ark/.config/retroarch32/retroarch.cfg
	sed -i '/savestate_auto_load \=/c\savestate_auto_load \= \"false\"' /home/ark/.config/retroarch/retroarch.cfg
	sed -i '/savestate_auto_load \=/c\savestate_auto_load \= \"false\"' /home/ark/.config/retroarch32/retroarch.cfg
	sed -i '/network_cmd_enable \=/c\network_cmd_enable \= \"false\"' /home/ark/.config/retroarch/retroarch.cfg
	sed -i '/network_cmd_enable \=/c\network_cmd_enable \= \"false\"' /home/ark/.config/retroarch32/retroarch.cfg
        sed -i '/savestate_auto_save \=/c\savestate_auto_save \= \"false\"' /home/ark/.config/retroarch/retroarch.cfg.bak
        sed -i '/savestate_auto_save \=/c\savestate_auto_save \= \"false\"' /home/ark/.config/retroarch32/retroarch.cfg.bak
        sed -i '/savestate_auto_load \=/c\savestate_auto_load \= \"false\"' /home/ark/.config/retroarch/retroarch.cfg.bak
        sed -i '/savestate_auto_load \=/c\savestate_auto_load \= \"false\"' /home/ark/.config/retroarch32/retroarch.cfg.bak
        sed -i '/network_cmd_enable \=/c\network_cmd_enable \= \"false\"' /home/ark/.config/retroarch/retroarch.cfg.bak
        sed -i '/network_cmd_enable \=/c\network_cmd_enable \= \"false\"' /home/ark/.config/retroarch32/retroarch.cfg.bak

	# Then let's remove setup the process for shutting down retroarch and retroarch32 during the unit shutdown process
	sudo rm -f /usr/local/bin/quickmode.sh
	# sudo systemctl disable firstboot
	# sudo systemctl stop firstboot
	sudo sed -i '/#After\=/s//\After\=/' /etc/systemd/system/oga_events.service
	sudo systemctl daemon-reload
	sudo cp -f /usr/local/bin/finish.sh.orig /usr/local/bin/finish.sh
        sudo cp -f /usr/local/bin/pause.sh.orig /usr/local/bin/pause.sh
	rm -f /home/ark/.config/lastgame.sh
	rm -f /home/ark/.emulationstation/scripts/game-end/wasitpng.sh
	rm -f /home/ark/.emulationstation/scripts/game-start/isitpng.sh
	# Replace Disable script with Enable script in Options/Advanced section
	sudo rm -f /opt/system/Advanced/"Disable Quick Mode.sh"
	cp -f /usr/local/bin/"Enable Quick Mode.sh" /opt/system/Advanced/.
	printf "\nQuick Mode has now been disabled."
	sleep 3
	exit 0
   fi

   Test_Button_B
   if [ "$?" -eq "10" ]; then
      printf "\nExiting without disabling Quick Mode."
      sleep 3
      exit 0
   fi
done
