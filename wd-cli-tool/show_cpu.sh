#!/bin/bash

# this script cSCtures memory cpu and temperature data

cSCture_data() {

    cpu=$(mpstat | awk '/all/ {print 100 - $NF}')
    mem=$(free | awk '/Mem/ {printf "%.2f", ($3 / $2) * 100}')
    #temperatura_atual=$(bc <<< "$(bc <<< "$(sensors | grep "Core 0:" | awk '{print $3}' | awk -F+ '{print $2}' | awk -F. '{print $1}')+$(sensors | grep "Core 1:" | awk '{print $3}' | awk -F+ '{print $2}' | awk -F. '{print $1}')+$(sensors | grep "Core 2:" | awk '{print $3}' | awk -F+ '{print $2}' | awk -F. '{print $1}')+$(sensors | grep "Core 3:" | awk '{print $3}' | awk -F+ '{print $2}' | awk -F. '{print $1}')")/4")
    temp=$(sensors | grep "Tctl:" | awk -F+ '{print $2}')
    data="$(date '+%F H%H:%M:%S') | cpu: $cpu | mem: $mem | temp: $temp"
    echo "$data"
}

cSCture_data