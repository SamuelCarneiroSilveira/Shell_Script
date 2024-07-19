#!/bin/bash

# This script ensures continuous synchronization between a source and
# destination directory. It first determines the source and destination
# directories from a configuration file. The script then continuously 
# checks if the source files exist in the destination. If not, it uses 
# rsync to transfer them. If the file exists but has a different size 
# in the source directory, the destination file is updated. This process 
# repeats indefinitely, ensuring the two directories remain synchronized.

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

source_directory="${SC_HOME}$(getConfigData 'files-recent')"
destination_directory="${SC_HOME}$(getConfigData 'files-storage')"

# Debug
echo "Directories $source_directory $destination_directory"

# Function to check if source and destination directories exist and to create them if necessary
checkDirectories() {
    echo "Checking directories..."

    ensureDirectoryExists "$source_directory"
    ensureDirectoryExists "$destination_directory"
}

while true; do
    # Check if source and destination directories exist
    checkDirectories

    # Loop through the files in the source directory
    for source_file in "$source_directory"/*; do
        # Check if the file is empty
        if [ ! -s "$source_file" ]; then
            echo "The file $source_file is empty. It will not be transferred."
            continue  # Skip to the next file without transferring
        fi

        # Check if the file already exists in the destination directory
        destination_file="$destination_directory/$(basename "$source_file")"
        if [ ! -f "$destination_file" ]; then
            # The file doesn't exist in the destination directory, so use rsync to transfer
            rsync -av "$source_file" "$destination_directory"

            # Check the exit code of rsync
            if [ $? -eq 0 ]; then
                echo "Transfer of the file $source_file completed successfully."
            else
                echo "Failed to transfer the file $source_file."
                exit 1  # Exit the script in case of failure
            fi
        else
            # The file already exists in the destination directory, check sizes
            source_size=$(stat -c %s "$source_file")
            destination_size=$(stat -c %s "$destination_file")
            if [ "$source_size" -eq "$destination_size" ]; then
                echo "The file $source_file already exists in the destination directory and is of the same size."
            elif [ "$source_size" -gt "$destination_size" ]; then
                # Source file has a larger size, replace the destination file
                rsync -av "$source_file" "$destination_file"
                echo "Replacement of the file $destination_file completed successfully."
            else
                echo "The file $source_file exists in the destination directory, but is of a smaller size."
            fi
        fi
    done

    echo "All files have been checked and transferred successfully."
    sleep 1
done
