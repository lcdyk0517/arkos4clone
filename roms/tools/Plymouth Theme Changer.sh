#!/bin/bash

#-----------------------------------
#THIS IS A MODIFIED Wifi.sh SCRIPT
#Made by Sucharek233
#---------------------------------++

#Shell setup start
CURR_TTY="/dev/tty1" #CHANGE TO TTY1!!!!!

sudo chmod 666 $CURR_TTY
#printf "\033c" > $CURR_TTY
reset

# hide cursor
printf "\e[?25l" > $CURR_TTY
dialog --clear

if test ! -z "$(cat /home/ark/.config/.DEVICE | grep RG503 | tr -d '\0')"
then
  height="20"
  width="60"
fi

export TERM=linux
export XDG_RUNTIME_DIR=/run/user/$UID/

if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
  if test ! -z "$(cat /home/ark/.config/.DEVICE | grep RG503 | tr -d '\0')"
  then
    sudo setfont /usr/share/consolefonts/Lat7-TerminusBold20x10.psf.gz
  else
    sudo setfont /usr/share/consolefonts/Lat7-TerminusBold22x11.psf.gz
  fi
else
  sudo setfont /usr/share/consolefonts/Lat7-Terminus16.psf.gz
fi

pgrep -f gptokeyb | sudo xargs kill -9
pgrep -f osk.py | sudo xargs kill -9
printf "\033c" > $CURR_TTY
printf "Starting Plymouth Manager.  Please wait..." > $CURR_TTY
#Shell setup end


height="15"
width="55"

BACKTITLE="Plymouth theme applier"

themesPath="/roms/tools/plymouthThemes"
targetPath="/usr/share/plymouth/themes"

ExitMenu() {
  printf "\033c" > $CURR_TTY
  if [[ ! -z $(pgrep -f gptokeyb) ]]; then
    pgrep -f gptokeyb | sudo xargs kill -9
  fi
  if [[ ! -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
    sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  fi
  exit 0
}

SaveOld() {
    if [[ ! -f "$targetPath/text.plymouth.orig" ]]; then
        sudo cp "$targetPath/text.plymouth" "$targetPath/text.plymouth.orig"
    fi  
}

ApplyTheme() {
    theme=$1
    themePath="$themesPath/$theme"
    
    themeValid=false
    for file in "$themePath"/*; do
        if [[ "$file" == *.plymouth ]]; then
            themeValid=true
            break
        fi
    done

    if ! $themeValid; then
        dialog --clear \
        --backtitle "$BACKTITLE" \
        --msgbox "No .plymouth file found! \nDid you copy the correct folder?" 6 50 > $CURR_TTY

        ListThemes
    fi
    
    themeSize=$(du -m --max-depth=0 "$themesPath/$theme" | cut -f1)
    freeSpace=$(df --output=avail -m "$targetPath" | sed '1d;s/[^0-9]//g')

    if [ $themeSize -gt $freeSpace ]; then
      dialog --clear \
        --backtitle "$BACKTITLE" \
        --msgbox "Selected theme is too large!\nTheme size: $themeSize MB\nFree space: $freeSpace MB" 7 50 > $CURR_TTY
        
      ListThemes
    fi

    SaveOld

    sudo rm "$targetPath/text.plymouth"
    if [[ -f "$targetPath/appliedTheme" ]]; then
      oldTheme=$(cat "$targetPath/appliedTheme")

      if [[ "$oldTheme" == "$theme" ]]; then
        dialog --clear \
        --backtitle "$BACKTITLE" \
        --msgbox "This theme is already active! \nPlease choose another one!" 6 50 > $CURR_TTY
        ListThemes
      fi

      sudo rm -rf "$targetPath/$oldTheme"
    fi

    #sudo ln -s "$themePath" "$targetPath/$theme"
    sudo cp -r "$themePath" "$targetPath/$theme"
    #sudo ln -s "$targetPath/$theme/$theme.plymouth" "$targetPath/text.plymouth"
    sudo cp "$targetPath/$theme/$theme.plymouth" "$targetPath/text.plymouth"

    sudo sh -c "echo "$theme" > "$targetPath/appliedTheme""

    # distro version in ES
    version=$(grep '^title=' "$targetPath/text.plymouth.orig")
    sudo sh -c "echo '$version' >> '$targetPath/text.plymouth'"

    dialog --clear \
    --backtitle "$BACKTITLE" \
    --msgbox "Theme has been applied!" 5 50 > $CURR_TTY

    MainMenu
}

ListThemes() {
    availableThemes=()
    if [ -d "$themesPath" ]; then
        echo "nice xd"
    elif [ -d "./plymouthThemes" ]; then
        themesPath="$(pwd)/plymouthThemes"
    else
        dialog --clear \
        --backtitle "$BACKTITLE" \
        --msgbox "No themes found! \nPlease make a folder called 'plymouthThemes' in the tools folder in the EASYROMS partition and paste your theme in there!" 8 50 > $CURR_TTY
        
        MainMenu
    fi

    for t in "$themesPath"/*; do
        if [ -d "$t" ]; then
            themeName="${t//$themesPath\//}"
            availableThemes+=("$themeName" "")
        fi
    done

    while true; do
        cselection=(dialog \
        --backtitle "$BACKTITLE" \
        --title "Available Themes" \
        --no-collapse \
        --clear \
        --cancel-label "Back" \
        --ok-label "Apply" \
        --menu "Select a theme" $height $width 15)

        cchoices=$("${cselection[@]}" "${availableThemes[@]}" 2>&1 > $CURR_TTY) || MainMenu
        
        if [[ $? != 0 ]]; then
            exit 1
        fi

        for cchoice in $cchoices; do
            case $cchoice in
                *) ApplyTheme $cchoice ;;
            esac
        done
    done
}

Preview() {
    sudo pkill plymouthd
    sudo pkill plymouth

    sudo plymouthd
    sudo plymouth --show-splash
    sleep 5
    sudo plymouth --hide-splash

    sudo pkill plymouthd
    sudo pkill plymouth
}

Revert() {
    if [[ ! -f "$targetPath/text.plymouth.orig" ]]; then
        dialog --clear \
        --backtitle "$BACKTITLE" \
        --msgbox "Original theme has not been found!" 5 50 > $CURR_TTY

        MainMenu
    fi

    sudo rm "$targetPath/text.plymouth"
    sudo cp "$targetPath/text.plymouth.orig" "$targetPath/text.plymouth"

    dialog --clear \
    --backtitle "$BACKTITLE" \
    --msgbox "Original theme has been restored" 5 50 > $CURR_TTY
}


MainMenu() {
  while true; do
    mainselection=(dialog \
        --backtitle "$BACKTITLE" \
        --title "" \
        --no-collapse \
        --clear \
        --cancel-label "Select + Start to Exit" \
        --menu "Main Menu" $height $width 15)
        mainoptions=( 1 "Select new theme" 2 "Preview current theme (5 seconds)" 3 "Revert to default" 4 "Exit" )
        mainchoices=$("${mainselection[@]}" "${mainoptions[@]}" 2>&1 > $CURR_TTY)
        if [[ $? != 0 ]]; then
          exit 1
        fi
    for mchoice in $mainchoices; do
      case $mchoice in
        1) ListThemes ;;
        2) Preview ;;
        3) Revert ;;
        4) ExitMenu ;;
      esac
    done
  done
}

#
# Joystick controls
#
# only one instance

sudo chmod 666 /dev/uinput
export SDL_GAMECONTROLLERCONFIG_FILE="/opt/inttools/gamecontrollerdb.txt"
if [[ ! -z $(pgrep -f gptokeyb) ]]; then
  pgrep -f gptokeyb | sudo xargs kill -9
fi
/opt/inttools/gptokeyb -1 "Plymouth Theme Changer.sh" -c "/opt/inttools/keys.gptk" > /dev/null 2>&1 &
#sudo pkill tm-joypad > /dev/null 2>&1
#sudo /opt/system/Tools/ThemeMaster/tm-joypad Wifi.sh rg552 > /dev/null 2>&1 &
#sudo /opt/wifi/oga_controls Wifi rg552 > /dev/null 2>&1 &
printf "\033c" > $CURR_TTY
dialog --clear
trap ExitMenu EXIT

MainMenu