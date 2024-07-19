#!/bin/bash

# This script manages storage logs for a user. It ensures that necessary directories exist, 
# manages the creation of daily storage logs, and handles any discrepancies in storage log names.

# Function to fetch a particular configuration from a config file
getConfigData() {
    # Search the provided configuration in the file
    # Cut out the value based on '=' delimiter
    # Remove any whitespace characters
    grep "^$1=" "$config_txt" | cut -d'=' -f2 | tr -d '[:space:]'
}

# Function to ensure a given directory exists
ensureDirectoryExists() {
    path="$1"

    # Check if path was provided
    if [ -z "$path" ]; then
        echo "Path not provided"
        return
    fi

    # Always get the parent directory of the provided path
    path=$(dirname "$path")

    # If directory doesn't exist, create it
    if [ ! -d "$path" ]; then
        echo "Creating $path"
        sudo mkdir -p "$path"
    fi
}

# Ensure that the script is executed with sudo
if [ -z "${SC_USER}" ]; then
    echo "Error: Script must be executed with sudo."
    exit 1
fi

# Locate the configuration file within the specified directory
config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)
if [ -z "$config_txt" ]; then
    echo "Error: Configuration file not found."
    exit 1
fi

# Fetch configurations from the file
log_folder="${SC_HOME}$(getConfigData 'log')"
log_toBucket_directory="${SC_HOME}$(getConfigData 'log_toBucket_directory')"
log_storage_backup_directory="${SC_HOME}$(getConfigData 'log_storage_backup_directory')"

# Ensure the necessary directories exist
ensureDirectoryExists "$log_folder"
ensureDirectoryExists "$log_toBucket_directory"
ensureDirectoryExists "$log_storage_backup_directory"

# Function to handle daily storage logs
function dayStorages() {
    # Determine today's date and SCpend to storage.log name format
    storage_date="$(date +"%d_%m_%Y_")storage.log"

    # If today's log doesn't exist, create it in the main folder
    if [ ! -f "$log_folder/$storage_date" ]; then
        echo "Creating today's storage.log"
        touch "$log_folder/$storage_date"
    fi

    # If today's log doesn't exist, create it in the toBucket directory
    if [ ! -f "$log_toBucket_directory/$storage_date" ]; then
        echo "Creating toBucket/storage.log for today."
        touch "$log_toBucket_directory/$storage_date"
    fi
}

# Function to handle discrepancies in storage log names
function handleStorageLogs() {
    for file in "$1"/*; do
        # If the file is a storage log
        if [[ "$file" == *storage.log ]]; then
            file_name=$(basename "$file")

            # If the file name doesn't match today's date
            if [[ "$file_name" != "$storage_date" ]]; then
                # If we're in the toBucket directory, remove the incorrect file
                if [[ "$1" == "$log_toBucket_directory" ]]; then
                    echo "In toBucket, the name of $file_name is not the same as $storage_date! Removing!"
                    sudo rm -rf "$file"
                else
                    # Move the incorrect file to the backup directory
                    echo "The name of $file_name is not the same as $storage_date"
                    mv "$file" "$log_storage_backup_directory/$file_name"
                    echo "File $file_name moved to $log_storage_backup_directory/$file_name"
                fi
            fi
        fi
    done
}

# Infinite loop to continuously manage storage logs
while true; do
    dayStorages
    handleStorageLogs "$log_folder"
    handleStorageLogs "$log_toBucket_directory"
    sleep 1  # Pause for 1 second before repeating
done
