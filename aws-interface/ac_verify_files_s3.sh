#!/bin/bash

# This script is intended to synchronize files between a local directory and an AWS S3 bucket.
# The following are the tasks this script performs:
# - Check for internet connectivity and for AWS S3 connectivity.
# - Compare files in a local directory with those in another local storage directory and an AWS S3 bucket.
# - Depending on file presence and file sizes, it makes decisions to upload or delete files.

# This function fetches the value of a specified configuration key from the configuration file.
getConfigData() {
    grep "^$1=" "$config_txt" | cut -d'=' -f2 | tr -d '[:space:]'
}

# This function ensures that a specific directory exists or creates it if it doesn't.
ensureDirectoryExists() {
    path="$1"
    if [ -z "$path" ]; then
        echo "Path not provided"
        return
    fi
    path=$(dirname "$path")
    if [ ! -d "$path" ]; then
        echo "Creating $path"
        sudo mkdir -p "$path"
    fi
}

# Ensure the script is run with sudo privileges.
if [ -z "${SC_USER}" ]; then
    echo "Error: Script must be run with sudo."
    exit 1
fi

# Find the configuration file.
config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)
if [ -z "$config_txt" ]; then
    echo "Error: Configuration file not found."
    exit 1
fi

# Retrieve configuration values.
aws_link="$(getConfigData 's3_region_link_to_ping')"
bucket="$(getConfigData 'bucket')"
device="/${SC_USER}"
directory_recent="${SC_HOME}$(getConfigData 'files-recent')"
directory_storage="${SC_HOME}$(getConfigData 'files-storage')"

ensureDirectoryExists "$directory_recent"
ensureDirectoryExists "$directory_storage"

# Debugging statements to display configuration values.
# echo "Recent Directory: $directory_recent"
# echo "Storage Directory: $directory_storage"
# echo "Selected bucket is $bucket"
# echo "Selected device should be the home name: $device"
# echo "Directory in bucket: $bucket$device"
# echo "sudo user: ${SC_USER}"
# echo "config file: $config_txt"
# echo "AWS link: $aws_link"

# Function to check internet connectivity.
check_internet_connection() {    
    if ping -c 1 8.8.8.8 &> /dev/null; then
        return 0  # True, there is an internet connection.
    else
        return 1  # False, there isn't an internet connection.
    fi
}

# Function to check connectivity with AWS S3.
check_aws_connection(){
    if curl -I "$aws_link" &> /dev/null; then
        return 0  # True, connected to AWS.
    else
        return 1  # False, not connected to AWS.
    fi
}

# Function to upload a specified file to the AWS S3 bucket.
upload_to_bucket() {
    local file="$1"
    sudo aws s3 cp "$file" "$bucket$device/$(basename "$file")"
    if [ $? -eq 0 ]; then
        echo "Successful upload to the bucket."
    else
        echo "Failed to upload to the bucket."
        # Additional actions for upload failure can be added here.
    fi
}

check_upload_success() {
    if [ $? -eq 0 ]; then
        echo "Successful upload to the bucket."
    else
        echo "Failed to upload to the bucket."
        # Additional actions for upload failure can be added here.
    fi
}

# Function to process files, compare with S3, and determine actions.
execute_action_for_files() {
    # echo "Processing files 2..."
    while IFS= read -r -d '' file; do
        echo "Action for: $(basename "$file")"
        if [ -f "$directory_storage/$(basename "$file")" ]; then
            echo "The file also exists in the other local directory."
            size_in_other_dir=$(stat -c %s "$directory_storage/$(basename "$file")")
            local_size=$(stat -c %s "$file")

            if [ "$local_size" -eq "$size_in_other_dir" ]; then
                echo "Sizes are the same."
                size_on_bucket=$(aws s3 ls "$bucket$device/$(basename "$file")" --summarize | grep $(basename "$file") | awk -F"$(basename "$file")" '{ print $1 }' | awk '{print $3}')
                if [ -n "$size_on_bucket" ]; then
                    echo "File $(basename "$file") exists in the bucket."
                    echo "Local size: $local_size bytes"
                    echo "Bucket size: $size_on_bucket bytes"
                    if [ "$local_size" -eq "$size_on_bucket" ]; then
                        echo "Sizes match."
                        rm "$file"  # Delete the local file
                        echo "Local file deleted."
                    else
                        echo "Sizes differ, re-uploading."
                        upload_to_bucket "$file"
                        check_upload_success
                    fi
                else
                    echo "File doesn't exist in the bucket. Uploading..."
                    upload_to_bucket "$file"
                    check_upload_success
                fi
            else
                echo "Sizes differ."
                if [[ $local_size -gt $size_on_bucket ]]; then
                    echo "Re-uploading because the file in the bucket is smaller."
                    upload_to_bucket "$file"
                    check_upload_success
                else
                    echo "The file in the bucket is larger."
                fi
            fi
        else
            echo "The file doesn't exist in the other local directory. Waiting for the other script to update the directory."
        fi
    done < <(find "$directory_recent" -type f -print0)
}

# Main loop to keep checking and synchronizing files.
while true; do
    if check_aws_connection && check_internet_connection; then
        # echo "Processing files 1..."
        execute_action_for_files
    else
        echo "No internet or AWS connection available."
    fi
    sleep 1;
done


