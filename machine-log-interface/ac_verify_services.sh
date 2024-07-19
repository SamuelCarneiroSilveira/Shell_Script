#!/bin/bash

# This script searches for services every 5 minutes. If a service is not running, 
# its name along with the current date is written to service.log.

# FUNCTION TO RETRIEVE CONFIG DATA
getConfigData() {
    # Extract the specific configuration data from the config file.
    grep "^$1=" "$config_txt" | cut -d'=' -f2 | tr -d '[:space:]'
}

# ENSURE DIRECTORY EXISTS
ensureDirectoryExists() {
    local path="$1"
    if [ -z "$path" ]; then
        echo "Error: Path not provided."
        return
    fi

    # Always fetch the parent directory of the provided path.
    path=$(dirname "$path")

    if [ ! -d "$path" ]; then
        echo "Creating directory: $path"
        sudo mkdir -p "$path"
    fi
}

# CHECK PERMISSIONS AND DIRECTORIES
if [ -z "${SC_USER}" ]; then
    echo "Error: The script must be executed with sudo privileges."
    exit 1
fi

# Locate the config file within the "shell-manager" directory.
config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)

if [ -z "$config_txt" ]; then
    echo "Error: Configuration file not found."
    exit 1
fi

# Fetch various paths and settings from the config file.
log_folder="${SC_HOME}$(getConfigData 'log')"
shell_folder="${SC_HOME}$(getConfigData 'shell-manager')"
service_log_file="${SC_HOME}$(getConfigData 'service_log_file')"
cron_temporary_service_log_file="${SC_HOME}$(getConfigData 'cron_temporary_service_log_file')"

# Ensure all the necessary directories and files exist.
ensureDirectoryExists "$log_folder"
ensureDirectoryExists "$shell_folder"
ensureDirectoryExists "$service_log_file"
ensureDirectoryExists "$cron_temporary_service_log_file"
touch "$service_log_file"
touch "$cron_temporary_service_log_file"

# Begin the main service checking loop.
while true; do
    erro=0
    current_timestamp="$(date '+%F, H%H:%M:%S, ')"

    # Iterate over all files starting with "SC_" in the shell folder.
    while IFS= read -r file; do
        # Check if the file actually exists.
        if [ -f "$file" ]; then
            # Execute the pgrep command with the full filename as an argument.
            resultado=$(pgrep -f "$file")
            
            file_without_ac="${file##*/SC_}"

            # If the result is empty, log the non-active service.
            if [ -z "$resultado" ]; then
                log_message="FAIL:$file_without_ac"
                
                echo -n "$current_timestamp" >> "$service_log_file"
                echo "$log_message" >> "$service_log_file"
                
                echo -n "$current_timestamp" >> "$cron_temporary_service_log_file"
                echo "$log_message" >> "$cron_temporary_service_log_file"
                
                erro=1
            fi
        fi
    done < <(find "$shell_folder" -type f -name 'SC_*')

    # If there were no errors, log that there were no issues.
    if [ $erro -eq 0 ]; then
        echo "$current_timestamp No Errors" >> "$cron_temporary_service_log_file"
        echo "$current_timestamp No Errors" >> "$service_log_file"
    fi

    # Wait for 5 minutes before the next iteration.
    echo "Waiting 5 minutes..."
    sleep 300
done
