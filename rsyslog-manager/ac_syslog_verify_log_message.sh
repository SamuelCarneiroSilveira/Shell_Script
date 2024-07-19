#!/bin/bash

# This script manages log messages 

# If a CRITICAL was found, this script does nothing, the verify critical script is
# responsable to handle this.

# If a ERROR was found, this script save in log and clean message file  

# Check if the script is run with sudo privileges.
if [ -z "${SC_USER}" ]; then
    echo "Error: Script must be run with sudo."
    exit 1
fi


# This function retrieves configuration data from the specified file.
getConfigData() {
    grep "^$1=" "$config_txt" | cut -d'=' -f2 | tr -d '[:space:]'
}

# This function ensures that a given directory exists.
ensureDirectoryExists() {
    path="$1"
    if [ -z "$path" ]; then
        echo "Path not provided"
        return
    fi

    # Get the parent directory.
    path=$(dirname "$path")

    if [ ! -d "$path" ]; then
        echo "Creating $path"
        sudo mkdir -p "$path"
    fi
}


config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)

echo "tese $config_txt"


# # Locate the configuration file.
# config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)


if [ -z "$config_txt" ]; then
    echo "Error: Configuration file not found."
    exit 1
fi

shell_log="${SC_HOME}$(getConfigData 'log')"
ensureDirectoryExists "$shell_log"

saveLog() {
    #Script que salva e limpa o log
    echo "saving log..."
    cat /var/log/messages >> $shell_log/storage.log 
    
}

addCpuData() {
    
    cpu=$(mpstat | awk '/all/ {print 100 - $NF}')
    mem=$(free | awk '/Mem/ {printf "%.2f", ($3 / $2) * 100}')
    #temperatura_atual=$(bc <<< "$(bc <<< "$(sensors | grep "Core 0:" | awk '{print $3}' | awk -F+ '{print $2}' | awk -F. '{print $1}')+$(sensors | grep "Core 1:" | awk '{print $3}' | awk -F+ '{print $2}' | awk -F. '{print $1}')+$(sensors | grep "Core 2:" | awk '{print $3}' | awk -F+ '{print $2}' | awk -F. '{print $1}')+$(sensors | grep "Core 3:" | awk '{print $3}' | awk -F+ '{print $2}' | awk -F. '{print $1}')")/4")
    temp=$(sensors | grep "Tctl:" | awk -F+ '{print $2}')

    data="$(date '+%F, %H:%M:%S') | cpu: $cpu | mem: $mem | temp: $temp"

    # Saves to storage.log
    echo $data >> $shell_log/storage.log
}

cleanMessage() {   
    echo "Cleaning messages... "

    sudo rm /var/log/messages 
    sudo service rsyslog restart
}


while true; do
    
    # Verify if there is any messages file
    while [ -f /var/log/messages ]; do
        
        log_error_tag=$(cat /var/log/messages | grep "#CRITICAL")    
        echo "message file exist, $log_error_tag"
        
        case $log_error_tag in
            "CRITICAL")
                echo "critical, waits for verify critical..."
                break
                ;;
            "ERROR")

                saveLog
                addCpuData
                cleanMessage

                # ESPECIFIC ACTION HERE
                
                # Breaks infinity loop
                break
                ;;
            *)
                # UNKNOWN ERROR TAG
                
                echo "There is no action especified for: $log_error_tag"

                saveLog
                addCpuData
                cleanMessage

                ;;
        esac
    done
    sleep 1  # Aguarda 1 segundo antes da próxima iteração
    # for debug
    echo "Running..." 
done
