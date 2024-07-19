#!/bin/bash

# This script is designed to monitor and clean the crontab log files. 
# If any log file exceeds 1MB, it will be deleted to prevent system overload.

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

# CHECK SCRIPT EXECUTION PERMISSIONS
if [ -z "${SC_USER}" ]; then
    echo "Error: The script must be executed with sudo privileges."
    exit 1
fi

# LOCATE THE CONFIGURATION FILE
config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)
if [ -z "$config_txt" ]; then
    echo "Error: Configuration file not found."
    exit 1
fi

# RETRIEVE LOG AND CRONTAB DIRECTORY INFORMATION FROM CONFIG FILE
log_folder="${SC_HOME}$(getConfigData 'log')"
crontab_folder="${SC_HOME}$(getConfigData 'crontab_folder')"

# ENSURE CRONTAB LOG DIRECTORY EXISTS
ensureDirectoryExists "$crontab_folder"
ensureDirectoryExists "$log_folder"

# FUNCTION TO DELETE FILES LARGER THAN 1MB
deleteLargeFiles() {
    # Check if there are files in the crontab log directory.
    if [ -z "$(ls -A "$crontab_folder")" ]; then
        echo "No files in the crontab log directory."
        return
    fi

    # Iterate over each log file in the directory.
    for log_file in "$crontab_folder"/*; do
        # Skip if the item is not a regular file
        if [ ! -f "$log_file" ]; then
            continue
        fi

        # Get the file size in bytes.
        file_size=$(stat -c %s "$log_file")
        max_size=$((1024 * 1024))  # 1MB in bytes
        
        # Check if the file size exceeds 1MB.
        if [ "$file_size" -gt "$max_size" ]; then
            echo "Large file detected! Removing $(basename "$log_file")."
            rm "$log_file"
        else
            echo "The file $(basename "$log_file") is smaller than 1MB."
        fi
    done
}

# MAIN LOOP TO CONTINUOUSLY MONITOR AND CLEAN LOG FILES
while true; do
    deleteLargeFiles
    sleep 1  # 1-second delay before checking again
done
