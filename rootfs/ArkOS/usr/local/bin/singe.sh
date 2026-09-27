#!/bin/bash

directory=$(dirname "$1" | cut -d "/" -f2)
unlink /opt/hypseus-singe/roms
ln -sfv /$directory/alg/roms/ /opt/hypseus-singe/roms

if [[ $1 == "/$directory/alg/Scan_for_new_games.alg" ]]
then
  printf "\033c" >> /dev/tty1
  cd /$directory/alg
  ./Scan_for_new_games.alg
  printf "\n\nFinished scanning the alg folder for games." >> /dev/tty1
  printf "\nPlease restart emulationstaton to find the new shortcuts" >> /dev/tty1
  printf "\ncreated if any.\n" >> /dev/tty1
  sleep 5
  printf "\033c" >> /dev/tty1
  exit 1
fi

HYPSEUS_BIN=/opt/hypseus-singe/hypseus-singe
HYPSEUS_SHARE=/$directory/alg
HYPSEUS_HOME=/opt/hypseus-singe

dir="$1"
basedir=$(basename -- $dir)
SINGEGAME=${basedir%.*}

function STDERR () {
	/bin/cat - 1>&2
}

#if [ "$SINGEGAME" = "-fullscreen" ] || [ "$(cat ~/.config/.DEVICE)" = "RG503" ] || [ "$(cat ~/.config/.DEVICE)" = "RGB10MAX" ]; then
    FULLSCREEN="-fullscreen"
    shift
#fi

if [ "$SINGEGAME" = "-blend" ]; then
    BLEND="-blend_sprites"
    shift
fi

if [ "$SINGEGAME" = "-nolinear" ]; then
    NEAREST="-nolinear_scale"
    shift
fi

if [ -z $SINGEGAME ] ; then
	echo "Specify a game to try: " | STDERR
	echo
	echo "$0 [-fullscreen] [-blend] [-nolinear] <gamename>" | STDERR
	echo

        echo "Games available: "
	for game in $(ls $HYPSEUS_SHARE/); do
		if [ $game != "actionmax" ]; then
			installed="$installed $game"
		fi
        done
        echo "$installed" | fold -s -w60 | sed 's/^ //; s/^/\t/' | STDERR
	echo
	exit 1
fi

if [ ! -f $HYPSEUS_SHARE/$SINGEGAME/$SINGEGAME.singe ] || [ ! -f $HYPSEUS_SHARE/$SINGEGAME/$SINGEGAME.txt ]; then
        echo
        echo "Missing file: $HYPSEUS_SHARE/$SINGEGAME/$SINGEGAME.singe ?" | STDERR
        echo "              $HYPSEUS_SHARE/$SINGEGAME/$SINGEGAME.txt ?" | STDERR
        echo
        exit 1
fi

sudo systemctl start singehotkey.service
#rm /home/ark/.asoundrc
#xres="$(cat /sys/class/graphics/fb0/modes | grep -o -P '(?<=:).*(?=p-)' | cut -dx -f1)"
#if [ $xres -ge "1280" ]; then
#  HDMI="/usr/lib/aarch64-linux-gnu/libSDL2-2.0.so.0.10.0"
#fi

#LD_PRELOAD="$HDMI" $HYPSEUS_BIN singe vldp \
$HYPSEUS_BIN singe vldp \
-framefile $HYPSEUS_SHARE/$SINGEGAME/$SINGEGAME.txt \
-script $HYPSEUS_SHARE/$SINGEGAME/$SINGEGAME.singe \
-homedir $HYPSEUS_HOME \
-datadir $HYPSEUS_HOME \
$FULLSCREEN \
$NEAREST \
$BLEND
#-set_overlay oversize
#-sound_buffer 2048 \
#-volume_nonvldp 5 \
#-volume_vldp 20

EXIT_CODE=$?

if [ "$EXIT_CODE" -ne "0" ] ; then
	if [ "$EXIT_CODE" -eq "127" ]; then
		echo ""
		echo "Hypseus Singe failed to start." | STDERR
		echo "This is probably due to a library problem." | STDERR
		echo "Run hypseus.bin directly to see which libraries are missing." | STDERR
		echo ""
	else
		echo "Loader failed with an unknown exit code : $EXIT_CODE." | STDERR
	fi
	exit $EXIT_CODE
fi
sudo systemctl stop singehotkey.service
#cp /home/ark/.asoundrcbak /home/ark/.asoundrc
