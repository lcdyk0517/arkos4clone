#!/bin/sh

cd "$(dirname "$0")"
cp -v panel1.cfg gamma.cfg
sudo systemctl restart gamma-correction.service
