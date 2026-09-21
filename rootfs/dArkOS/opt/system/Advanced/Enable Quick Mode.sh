#!/bin/bash

################################################################################################
# Thanks to stupidhoroscope for the breakdown on how this is achieved in OnionOS               #
################################################################################################

. /usr/local/bin/buttonmon.sh

printf "\nAre you sure you want to enable Quick Mode?"
printf "\nPress A to continue.  Press B to exit.\n"

while true
do
   Test_Button_A
   if [ "$?" -eq "10" ]; then
	printf "\nEnabling Quick Mode.  Please wait...\n"
	# First let's setup retroarch and retroarch32 to create autosaves and autoload savestates on game launch
	sed -i '/savestate_auto_save \=/c\savestate_auto_save \= \"true\"' /home/ark/.config/retroarch/retroarch.cfg
	sed -i '/savestate_auto_save \=/c\savestate_auto_save \= \"true\"' /home/ark/.config/retroarch32/retroarch.cfg
	sed -i '/savestate_auto_load \=/c\savestate_auto_load \= \"true\"' /home/ark/.config/retroarch/retroarch.cfg
	sed -i '/savestate_auto_load \=/c\savestate_auto_load \= \"true\"' /home/ark/.config/retroarch32/retroarch.cfg
	sed -i '/network_cmd_enable \=/c\network_cmd_enable \= \"true\"' /home/ark/.config/retroarch/retroarch.cfg
	sed -i '/network_cmd_enable \=/c\network_cmd_enable \= \"true\"' /home/ark/.config/retroarch32/retroarch.cfg
	sed -i '/savestate_auto_save \=/c\savestate_auto_save \= \"true\"' /home/ark/.config/retroarch/retroarch.cfg.bak
	sed -i '/savestate_auto_save \=/c\savestate_auto_save \= \"true\"' /home/ark/.config/retroarch32/retroarch.cfg.bak
	sed -i '/savestate_auto_load \=/c\savestate_auto_load \= \"true\"' /home/ark/.config/retroarch/retroarch.cfg.bak
	sed -i '/savestate_auto_load \=/c\savestate_auto_load \= \"true\"' /home/ark/.config/retroarch32/retroarch.cfg.bak
	sed -i '/network_cmd_enable \=/c\network_cmd_enable \= \"true\"' /home/ark/.config/retroarch/retroarch.cfg.bak
	sed -i '/network_cmd_enable \=/c\network_cmd_enable \= \"true\"' /home/ark/.config/retroarch32/retroarch.cfg.bak

	# Then let's setup the process for shutting down retroarch and retroarch32 during the unit shutdown process
	sudo touch /usr/local/bin/quickmode.sh
	echo '#!/bin/bash' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '' | sudo tee -a /usr/local/bin/quickmode.sh
	echo 'if [[ ! -z $(pgrep pico8) ]]; then' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  pkill lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sudo rm -f /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "%s%s%s%s\n" "#" "!" "/bin" "/bash" > /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo run-parts /var/spool/cron/crontabs/" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo systemctl stop emulationstation" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "touch /dev/shm/QBMODE" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  get_last_played.sh pico8 | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "if [[ -e /sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor ]]; then\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "  echo simple_ondemand > /sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "elif [[ -e /sys/devices/platform/fde60000.gpu/devfreq/fde60000.gpu/governor ]]; then\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "  echo dmc_ondemand > /sys/devices/platform/fde60000.gpu/devfreq/fde60000.gpu/governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "fi\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "echo interactive > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "echo dmc_ondemand > /sys/devices/platform/dmc/devfreq/dmc/governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sed -i "/  chmod/s//sudo chmod/" /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sed -i "/  echo/s//echo/" /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "pkill pico8_64\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "pkill pico8_dyn\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "rm /dev/shm/QBMODE" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "rm /home/ark/.config/lastgame.sh\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo systemctl restart firstboot &" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo systemctl restart emulationstation" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sudo chmod 777 /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sudo chown ark:ark /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  pkill pico8_64' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  pkill pico8_dyn' | sudo tee -a /usr/local/bin/quickmode.sh
	echo 'elif [[ ! -z $(pgrep -x retroarch) ]]; then' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  retroarch --verbose --command QUIT' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  retroarch --verbose --command QUIT' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  while pgrep -x retroarch >/dev/null; do sleep 0.1; done' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  #read -p "waiting..." -t 10' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  pkill lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sudo rm -f /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "%s%s%s%s\n" "#" "!" "/bin" "/bash" > /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo run-parts /var/spool/cron/crontabs/" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  #while pgrep -x retroarch >/dev/null; do sleep 0.1; done' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo systemctl stop emulationstation" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  if [[ -e /dev/shm/PNG_Loaded ]]; then' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '    echo "touch /dev/shm/PNG_Loaded" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  fi' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "touch /dev/shm/QBMODE" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  get_last_played.sh retroarch | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  if [[ -e /dev/shm/PNG_Loaded ]]; then' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '    echo "rm /dev/shm/PNG_Loaded" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  fi' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "if [[ -e /sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor ]]; then\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "  echo simple_ondemand > /sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "elif [[ -e /sys/devices/platform/fde60000.gpu/devfreq/fde60000.gpu/governor ]]; then\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "  echo dmc_ondemand > /sys/devices/platform/fde60000.gpu/devfreq/fde60000.gpu/governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "fi\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "echo interactive > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "echo dmc_ondemand > /sys/devices/platform/dmc/devfreq/dmc/governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sed -i "/  chmod/s//sudo chmod/" /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sed -i "/  echo/s//echo/" /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "rm /dev/shm/QBMODE" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "rm /home/ark/.config/lastgame.sh\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo systemctl restart firstboot &" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo systemctl restart emulationstation" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sudo chmod 777 /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sudo chown ark:ark /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sudo chown ark:ark /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo 'elif [[ ! -z $(pgrep -x retroarch32) ]]; then' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  retroarch32 --verbose --command QUIT' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  retroarch32 --verbose --command QUIT' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  while pgrep -x retroarch32 >/dev/null; do sleep 0.1; done' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  #read -p "waiting..." -t 15' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  pkill lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sudo rm -f /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "%s%s%s%s\n" "#" "!" "/bin" "/bash" > /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo run-parts /var/spool/cron/crontabs/" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  #while pgrep -x retroarch32 >/dev/null; do sleep 0.1; done' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo systemctl stop emulationstation" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "touch /dev/shm/QBMODE" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  get_last_played.sh retroarch32 | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "if [[ -e /sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor ]]; then\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "  echo simple_ondemand > /sys/devices/platform/ff400000.gpu/devfreq/ff400000.gpu/governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "elif [[ -e /sys/devices/platform/fde60000.gpu/devfreq/fde60000.gpu/governor ]]; then\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "  echo dmc_ondemand > /sys/devices/platform/fde60000.gpu/devfreq/fde60000.gpu/governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "fi\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "echo interactive > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "echo dmc_ondemand > /sys/devices/platform/dmc/devfreq/dmc/governor\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sed -i "/  chmod/s//sudo chmod/" /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sed -i "/  echo/s//echo/" /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "rm /dev/shm/QBMODE" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  printf "rm /home/ark/.config/lastgame.sh\n" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo systemctl restart firstboot &" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  echo "sudo systemctl restart emulationstation" | tee -a /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sudo chmod 777 /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo '  sudo chown ark:ark /home/ark/.config/lastgame.sh' | sudo tee -a /usr/local/bin/quickmode.sh
	echo 'fi' | sudo tee -a /usr/local/bin/quickmode.sh
	sudo chmod 777 /usr/local/bin/quickmode.sh

	# Copy some scripts to the emulationsation game-start and game-end directories
	# to account for how retroarch treats PNG files used by the fake08 core
	cp -f /usr/local/bin/isitpng.sh /home/ark/.emulationstation/scripts/game-start/isitpng.sh
	sudo chown ark:ark /home/ark/.emulationstation/scripts/game-start/isitpng.sh
	cp -f /usr/local/bin/wasitpng.sh /home/ark/.emulationstation/scripts/game-end/wasitpng.sh
	sudo chown ark:ark /home/ark/.emulationstation/scripts/game-end/wasitpng.sh

	# Reuse the dead firstboot systemctl service for use with Quick Mode
	# sudo sed -i '/ExecStart\=/c\ExecStart\=\/home\/ark\/.config\/lastgame.sh' /etc/systemd/system/firstboot.service
	# sudo sed -i '/User\=root/c\User\=ark' /etc/systemd/system/firstboot.service
	# sudo sed -i '/WorkingDirectory\=/c\WorkingDirectory\=\/home\/ark\/.config\/' /etc/systemd/system/firstboot.service

	# With Quick Mode, let's not hold up the hotkey deamon from starting since ES may not boot before in game
	sudo sed -i '/After\=/s//\#After\=/' /etc/systemd/system/oga_events.service
	sudo systemctl daemon-reload
	sudo systemctl enable firstboot

	# Change the shutdown and pause scripts to check if retroarch or pico-8 standalone is running
	sudo cp -f /usr/local/bin/finish.sh.qm /usr/local/bin/finish.sh
	sudo cp -f /usr/local/bin/pause.sh.qm /usr/local/bin/pause.sh

	# Replace Enable script with Disable script in Options/Advanced section
	sudo rm -f /opt/system/Advanced/"Enable Quick Mode.sh"
	cp -f /usr/local/bin/"Disable Quick Mode.sh" /opt/system/Advanced/.
	printf "\nQuick Mode is now enabled."
	sleep 3
	exit 0
   fi

   Test_Button_B
   if [ "$?" -eq "10" ]; then
      printf "\nExiting without enabling Quick Mode."
      sleep 3
      exit 0
   fi
done
