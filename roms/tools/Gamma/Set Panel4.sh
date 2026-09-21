#!/bin/sh

cd "$(dirname "$0")"
cp -v panel4.cfg gamma.cfg
sudo systemctl restart gamma-correction.service
