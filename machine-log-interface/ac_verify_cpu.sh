#!/bin/bash

# cSCture cpu data

# FUNCTION TO CATCH CONFIG DATA 
getConfigData() {
    grep "^$1=" "$config_txt" | cut -d'=' -f2 | tr -d '[:space:]'
}

ensureDirectoryExists() {
    path="$1"
    if [ -z "$path" ]; then
        echo "Path not provided"
        return
    fi

    # FATHER DIRECTORY
    path=$(dirname "$path")

    if [ ! -d "$path" ]; then
        echo "Creating $path"
        sudo mkdir -p "$path"
    fi
}


# VERIFY PERMISSIONS AND DIRECTORYS
if [ -z "${SC_USER}" ]; then
    echo "Erro: Script must be sudo."
    exit 1
fi

config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)
if [ -z "$config_txt" ]; then
    echo "Erro: Arquivo de configuração não encontrado."
    exit 1
fi

log_folder="${SC_HOME}$(getConfigData 'log')"
cron_temporary_cpu_log_file="${SC_HOME}$(getConfigData 'cron_temporary_cpu_log_file')"
cpu_log_file="${SC_HOME}$(getConfigData 'cpu_log_file')"

# Ensure necessary directories exist
ensureDirectoryExists "$log_folder"
ensureDirectoryExists "$cron_temporary_cpu_log_file"
ensureDirectoryExists "$cpu_log_file"

# Ensure files exist
touch "$cron_temporary_cpu_log_file"
touch "$cpu_log_file"


while true; do
    percentual_cpu=$(mpstat | awk '/all/ {print 100 - $NF}')
    percentual_memoria=$(free | awk '/Mem/ {printf "%.2f", ($3 / $2) * 100}')
    current_temperature=$(sensors | grep "Tctl:" | awk -F+ '{print $2}')

    data="$(date '+%F H%H:%M:%S') | cpu: $percentual_cpu | mem: $percentual_memoria | temp: $current_temperature"

    echo "$data" >> "$cpu_log_file"
    echo "$data" >> "$cron_temporary_cpu_log_file"

    # verify if temperature is over 95º ou 85º
    temperature_int=$(echo "$current_temperature" | sed 's/°C//')

    if (( $(bc <<< "$temperature_int > 94") )); then
        echo "The temperature is over 94°C, critical, reboot." >> "$cron_temporary_cpu_log_file"
        echo "The temperature is over 94°C, critical, reboot." >> "$cpu_log_file"
        
        echo "rebooting"
        bash $wd_scripts_folder/reboot.sh
    fi

    if (( $(bc <<< "$temperature_int > 84") )); then
        echo "The temperature is over 84°C, danger, reboots at 94°" >> "$cron_temporary_cpu_log_file"
        echo "The temperature is over 84°C, danger, reboots at 94°" >> "$cpu_log_file"
    fi

    echo "Waiting 5 minutes..."
    sleep 300
done
