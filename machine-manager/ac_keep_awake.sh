#!/bin/bash

# This script prevents the computer from going into sleep mode and restart at 2 am 

xvfb-run -s "-screen 0 1024x768x24" bash -c "gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'; gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'; gsettings set org.gnome.settings-daemon.plugins.power idle-dim false"

echo "turn on pc $(date), reboot is scheduled for 2 AM"

while true; do
    if [[ "$(date +%T)" == 02:00:0* ]]; then
        echo "$(date +%T) time is correct, rebooting..."
        sudo reboot 
    fi
    sleep 1
done
