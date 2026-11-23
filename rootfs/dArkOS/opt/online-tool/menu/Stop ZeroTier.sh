#!/bin/bash
# NAME: Stop ZeroTier
# Stop the ZeroTier daemon started by the Netplay tool.
sudo pkill -f /opt/online-tool/zerotier-one
printf "\033c" > /dev/tty1
