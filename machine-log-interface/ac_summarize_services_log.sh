#!/bin/bash

# This function summarize a temporary services file and return results
# for a daily log.

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

# Check if the script is run with sudo privileges.
if [ -z "${SC_USER}" ]; then
    echo "Error: Script must be run with sudo."
    exit 1
fi

# Locate the configuration file.
config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)
if [ -z "$config_txt" ]; then
    echo "Error: Configuration file not found."
    exit 1
fi

# Define directories and files from the configuration.
log_folder="${SC_HOME}$(getConfigData 'log')"
temp_dir="${SC_HOME}$(getConfigData 'crontab_temp')"
temp_service_file="${SC_HOME}$(getConfigData 'cron_temporary_service_log_file')"

create() {
    ensureDirectoryExists "$log_folder"
    ensureDirectoryExists "$temp_dir"
    ensureDirectoryExists "$temp_service_file"

    # Ensure Files exist
    touch $temp_service_file
    
    # Define storage date.
    storage_date="$(date +"%d_%m_%Y_")storage.log"

    # Check if the day's log file exists, if not, create it.
    if [ ! -f "$log_folder/$storage_date" ]; then 
        echo "Creating day log"
        touch $log_folder/$storage_date
    fi  
}

# This function checks if there are logs from multiple hours in the file.
searchDifferentTime() {
    last_line=$(tail -n 1 "$temp_service_file")
    last_hour=$(echo "$last_line" | cut -d 'H' -f 2 | cut -c 1-2)
    
    while IFS= read -r line; do
        line_hour=$(echo "$line" | cut -d 'H' -f 2 | cut -c 1-2)
        if [ "$last_hour" != "$line_hour" ]; then
            return 0  # Horários diferentes encontrados
        fi
    done < "$temp_service_file"

    return 1  # All timestamps are from the same hour
}

# This function clears all but the last line from the temporary log file.
cleanDiferentTime() {
    last_line=$(tail -n 1 "$temp_service_file")
    echo "$last_line" > "$temp_service_file"
    echo "Log file cleaned, retaining the last line: $temp_service_file"
}



function sendResponse {

    failed_scripts=""
    counter=0
    hora=0

    hora=$(head -n 1 "$temp_service_file" | cut -d 'H' -f 2 | cut -d ':' -f 1)
    echo "Hour from firts line $hora"

    while IFS= read -r line; do
        # Verifica se a linha contém a palavra "FAIL"
        if [[ "$line" == *"FAIL"* ]]; then
            # Extrai o nome do script SCós "FAIL:"
            script_name=$(echo "$line" | cut -d ':' -f 4)
            
            # Adiciona o nome do script à string failed_scripts
            if [ $counter -eq 0 ]; then
                failed_scripts="$script_name"
            else
                if [[ " $failed_scripts " == *" $script_name "* ]]; then
                    echo "The script '$script_name' is already in your list."
                else
                    echo "Adding '$script_name' to your list."
                    failed_scripts="$failed_scripts $script_name"
                fi
            fi

            ((++counter))
        fi
    done < <(head -n -1 "$temp_service_file")

    if [ -z "$failed_scripts" ]; then
        echo "H$hora All scripts are running." >> "$log_folder/$storage_date"
        echo "H$hora All scripts are running."
    else
        echo "H$hora the scripts $failed_scripts are not running."
        echo "H$hora the scripts $failed_scripts are not running." >> "$log_folder/$storage_date"             
    fi
}

while true; do

    create

    if searchDifferentTime; then
        sendResponse
        cleanDiferentTime
    fi
    
    sleep 5
done
