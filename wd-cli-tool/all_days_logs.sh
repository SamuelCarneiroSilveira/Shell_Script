#!/bin/bash

# This script must run through all days logs and show them


# LOCATE THE CONFIGURATION FILE
config_txt=$(find "$SC_HOME/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)
if [ -z "$config_txt" ]; then
    echo "Error: Configuration file not found."
    exit 1
fi

# FUNCTION TO RETRIEVE CONFIG DATA FROM CONFIG FILE
getConfigData() {
    # Extract the specific configuration data from the config file.
    grep "^$1=" "$config_txt" | cut -d'=' -f2 | tr -d '[:space:]'
}

# FUNCTION TO ENSURE A GIVEN DIRECTORY EXISTS
ensureDirectoryExists() {
    local path="$1"
    if [ -z "$path" ]; then
        echo "Error: Path not provided."
        return
    fi

    # Always retrieve the parent directory of the provided path.
    path=$(dirname "$path")

    if [ ! -d "$path" ]; then
        echo "Creating directory: $path"
        sudo mkdir -p "$path"
    fi
}

# RETRIEVE LOG AND CRONTAB DIRECTORY INFORMATION FROM CONFIG FILE
day_log_backup_folder="$SC_HOME$(getConfigData 'day_log_backup')"

ensureDirectoryExists "$day_log_backup_folder"

showAllLogs() {
    # Check if there are files in the crontab log directory.
    if [ -z "$(ls -A "$day_log_backup_folder")" ]; then
        echo "No files in the storage backup directory."
        return
    fi

    # Iterate over each log file in the directory.
    for log_file in "$day_log_backup_folder"/*"_storage.log"; do
        
        # Skip if the item is not a regular file
        if [ ! -f "$log_file" ]; then
            continue
        fi
    
        # # Show file
        echo "_______________________ $(basename $log_file) _______________________"
        echo ""
        cat $log_file
        echo ""

        # echo "localização e nome do arquivo $day_log_backup_folder/$log_file " 
    done
}


showAllLogs