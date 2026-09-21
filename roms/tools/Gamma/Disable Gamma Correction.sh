#!/bin/sh

cd "$(dirname "$0")"
sudo systemctl disable gamma-correction.service
sudo rm -v /etc/systemd/system/gamma-correction.service
./gamma -s 1
