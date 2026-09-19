#!/bin/bash

################################################################################################
# Created by Christian Haitian                                                                 #
# Includes some scripting from AmberELEC                                                       #
# https://github.com/AmberELEC/AmberELEC/blob/dev/packages/games/libretro/freej2me/freej2me.sh #
################################################################################################

directory="$(dirname "$3" | cut -d "/" -f2)"

if [ ! -f "/${directory}/bios/freej2me-lr.jar" ]; then
  cp -f /usr/local/bin/freej2me_files/freej2me-lr.jar /${directory}/bios/.
elif [[ $(cmp -s /usr/local/bin/freej2me_files/freej2me-lr.jar /${directory}/bios/freej2me-lr.jar) != 0 ]]; then
  cp -f /usr/local/bin/freej2me_files/freej2me-lr.jar /${directory}/bios/.
fi

if [ ! -f "/${directory}/bios/freej2me-plus-lr.jar" ]; then
  cp -f /usr/local/bin/freej2me_files/freej2me-plus-lr.jar /${directory}/bios/.
elif [[ $(cmp -s /usr/local/bin/freej2me_files/freej2me-plus-lr.jar /${directory}/bios/freej2me-plus-lr.jar) != 0 ]]; then
  cp -f /usr/local/bin/freej2me_files/freej2me-plus-lr.jar /${directory}/bios/.
fi

JDKDOWNLOAD="zulu11.48.21-ca-jdk11.0.11"

mkdir -p /${directory}/j2me/jdk

if [[ $(ls -l /${directory}/j2me/jdk/bin/java > /dev/null 2>&1 && echo $?) != 0 ]]; then
  if [ ! -f "/${directory}/j2me/jdk/${JDKDOWNLOAD}-linux_aarch64.tar.gz" ]; then
    echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      msgbox "Please connect to a wifi internet connection so the free JDK can be installed for this emulator.  You can also manually download and install the files per the ArkOS Emulator and Ports section for j2me from the ArkOS wiki."
      exit 1
    fi
    printf "Downloading the ${JDKDOWNLOAD} file, please wait...\n" > /dev/tty1
    cd /${directory}/j2me/jdk
    rm -f ${JDKDOWNLOAD}-linux_aarch64.tar.gz > /dev/null 2>&1
    wget -t 3 -T 60 --no-check-certificate "https://cdn.azul.com/zulu-embedded/bin/${JDKDOWNLOAD}-linux_aarch64.tar.gz" > /dev/tty1 2>&1
    if [ $? -ne 0 ]; then
      rm -f ${JDKDOWNLOAD}-linux_aarch64.tar.gz
      msgbox "The wifi internet connection is not stable or the resources is not currently available.  Please retry again."
      exit 1
    fi
  fi
  echo "Processing and installing ${JDKDOWNLOAD} please be patient..." > /dev/tty1
  cd /${directory}/j2me/jdk
  tar xvfz ${JDKDOWNLOAD}-linux_aarch64.tar.gz ${JDKDOWNLOAD}-linux_aarch64/lib > /dev/tty1 2>&1
  tar xvfz ${JDKDOWNLOAD}-linux_aarch64.tar.gz ${JDKDOWNLOAD}-linux_aarch64/bin > /dev/tty1 2>&1
  tar xvfz ${JDKDOWNLOAD}-linux_aarch64.tar.gz ${JDKDOWNLOAD}-linux_aarch64/conf > /dev/tty1 2>&1
  if [ $? -ne 0 ]; then
   msgbox "Something went wrong with attempting to process the ${JDKDOWNLOAD}-linux_aarch64.tar.gz file.  Either the existing file manually provided is bad or it needs to be downloaded and process again.  Please retry again."
   exit 1
  fi
  rm ${JDKDOWNLOAD}-linux_aarch64/lib/*.zip
  mv ${JDKDOWNLOAD}-linux_aarch64/* .
  rm lib/*.jar
  rm -rf ${JDKDOWNLOAD}-linux_aarch64*
  sudo chmod 777 /${directory}/j2me/jdk/bin/*
  printf "${JDKDOWNLOAD} has been successfully downloaded and installed! Now loading ${3}\n"
  sleep 3
fi

if [[ ! -x "/${directory}/j2me/jdk/bin/j2me" ]]; then
  sudo chmod 777 /${directory}/j2me/jdk/bin/*
fi

if [[ ! -z "$(tr -d '\0' < /proc/device-tree/compatible | grep rk3326)" ]] && [[ $(tty) != *"pts"* ]]; then
  cp /home/ark/.asoundrcbak /home/ark/.asoundrc
fi

export PATH=/${directory}/j2me/jdk/bin:$PATH
export JAVA_HOME=/${directory}/j2me/jdk
if [ ! -d "/$directory/j2me/rms" ]; then
  mkdir -p /$directory/j2me/rms
fi

if  [[ $1 == "freej2me-sa" ]]; then
  sdl_controllerconfig="190000004b4800000011000000010000,GO-Super Gamepad,x:b2,a:b1,b:b0,y:b3,back:b12,start:b13,dpleft:b10,dpdown:b9,dpright:b11,dpup:b8,leftshoulder:b4,lefttrigger:b6,rightshoulder:b5,righttrigger:b7,leftstick:b14,rightstick:b15,leftx:a0,lefty:a1,rightx:a2,righty:a3,platform:Linux,"
  SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig" /opt/freej2mesa/run.sh "$3"
else
  if [[ ! -z "$(tr -d '\0' < /proc/device-tree/compatible | grep rk3326)" ]] && [[ $(tty) != *"pts"* ]]; then
    cp /home/ark/.asoundrcbak /home/ark/.asoundrc
  fi

  if [ ! -d "/dev/shm/j2me/rms" ]; then
    mkdir -p /dev/shm/j2me
  fi

  ln -sf /$directory/j2me/rms /dev/shm/j2me

  retroarch -L /home/ark/.config/retroarch/cores/${2}_libretro.so "$3"

fi
