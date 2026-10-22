#!/bin/bash

center_screen() {
  clear
  local text="$*"
  local rows cols
  rows=$(tput lines)
  cols=$(tput cols)
  local text_lines=1

  # Move cursor to vertical center
  local v_padding=$(( (rows / 2) - (text_lines / 2) ))
  printf "\n%.0s" $(seq 1 $v_padding)

  # Print horizontally centered text
  printf "%*s\n" $(( (cols + ${#text}) / 2 )) "$text"
}

DISTRO_VERSION=$(cat /usr/share/plymouth/themes/text.plymouth | grep title | cut -c 7-50)
sudo setfont /usr/share/consolefonts/Lat2-Terminus24x12.psf.gz
# This runs right before EmulationStation starts, so every pause here delays it
# (stock: 0.5s + 1s)
center_screen "Welcome to $DISTRO_VERSION"
sleep 0.25
center_screen "Welcome to $DISTRO_VERSION"
sleep 0.25
clear
sudo setfont /usr/share/consolefonts/Lat15-Fixed16.psf.gz