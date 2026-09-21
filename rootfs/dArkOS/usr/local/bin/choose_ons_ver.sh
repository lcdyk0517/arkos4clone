#!/bin/bash

if  [[ $1 == "onscripter-sa" ]]; then
    /usr/local/bin/onscripter.sh "$3"
else
    /usr/local/bin/"$1" -L /home/ark/.config/"$1"/cores/"$2" "$3";
fi