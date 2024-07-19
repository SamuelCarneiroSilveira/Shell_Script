#!/bin/bash

# The script continuously syncs the storage.log from its primary 
# directory to the toBucket directory. If the log directories
# don't exist, it creates them. The script replaces the toBucket
# log with the primary log if the latter is larger. Additionally,
# each storage.log is prefixed with the current date, ensuring 
# a unique log for each day.

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

log_directory="${SC_HOME}$(getConfigData 'log')"
log_toBucket_directory="${SC_HOME}$(getConfigData 'log_toBucket_directory')"

create() {
    # Name the storage log with the current date.
    storage_date="$(date +"%d_%m_%Y_")storage.log"

    # echo "Checking directories..."
    ensureDirectoryExists "$log_directory"
    ensureDirectoryExists "$log_toBucket_directory"

    # Ensure files exist
    touch $log_directory/$storage_date
    touch $log_toBucket_directory/$storage_date

}

while true; do

    # Check if directories exist and create them if they don't.
    create

    # Determine the sizes of the storage logs in both directories.
    size1=$(stat -c "%s" "$log_directory/$storage_date")
    size2=$(stat -c "%s" "$log_toBucket_directory/$storage_date")

    # Print sizes for debugging purposes.
    # echo -n "Size 1: $size1 Size 2: $size2, "

    # If the file in log directory is larger, sync (replace) the one in toBucket directory.
    if [[ "$size1" -gt "$size2" ]]; then
        rsync -av "$log_directory/$storage_date" "$log_toBucket_directory/$storage_date"
        echo "File replaced."
        # Print sizes for debugging purposes.
        #else
        # echo "The file in the log directory is not larger than the one in toBucket."
    fi
    sleep 1
done
