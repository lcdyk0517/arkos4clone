#!/bin/sh

cd "$(dirname "$0")"
sudo cp -v systemd/gamma-correction.service /etc/systemd/system/
sudo systemctl enable gamma-correction.service
sudo systemctl start gamma-correction.service
