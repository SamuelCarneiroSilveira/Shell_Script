#!/bin/bash

# This script synchronizes files between a local directory and an AWS S3 bucket.
# It performs the following tasks:
# - Check internet and AWS S3 connectivity.
# - Compare files in a local directory with another local storage directory and an AWS S3 bucket.
# - Decide to upload or delete files based on file presence and file sizes.

# Function to retrieve the value of a given configuration key from the configuration file.
getConfigData() {
    grep "^$1=" "$config_txt" | cut -d'=' -f2 | tr -d '[:space:]'
}

# Function to ensure a directory exists or create it if it doesn't.
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

# Locate the configuration file.
config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)
if [ -z "$config_txt" ]; then
    echo "Error: Configuration file not found."
    exit 1
fi

# Retrieve configuration values.
log_toBucket_directory="${SC_HOME}$(getConfigData 'log_toBucket_directory')"
bucket="$(getConfigData 'bucket')"
device="/${SC_USER}"
storage_date="$(date +"%d_%m_%Y_")storage.log"

ensureDirectoryExists "$log_toBucket_directory"

echo "Log directory: $log_toBucket_directory"
echo "Bucket: $bucket"
echo "Device: $device"
echo "Bucket Device Directory: $bucket$device"

log_file="$log_toBucket_directory/$storage_date"
echo "Log file: $log_file"

# Function to upload file to S3.
uploadToS3() {
    local local_file="$1"
    local s3_path="$2"
    echo "Sending $local_file to $s3_path"
    sudo aws s3 cp "$local_file" "$s3_path"
}

# to check and synchronize files.

storage_date="$(date +"%d_%m_%Y_")storage.log"
log_file="$log_toBucket_directory/$storage_date"

# Check if the local file exists.
if [ -f "$log_file" ]; then
    echo "The file $log_file exists"
    # Get the size of the local file.
    local_file_size=$(stat -c "%s" "$log_file")
    echo "Local file size is $local_file_size"
    # Check if the file exists in S3.
    if sudo aws s3 ls "$bucket$device/$storage_date" >/dev/null 2>&1; then
        # Get the size of the file in S3.
        echo "File found in S3"
        
        
        cleanBucketName="$(echo "$bucket$device" | awk -F '//' '{print $2}' | awk -F '/' '{print $1}')"
        s3_file_size="$(aws s3SCi head-object --bucket "$cleanBucketName" --key "${SC_USER}/$storage_date" --query 'ContentLength' --output text)"
        echo "File size in S3 is $s3_file_size"
        
        
        
        # Check if variables are not empty.
        if [ -n "$local_file_size" ] && [ -n "$s3_file_size" ]; then
            # Compare file sizes.
            if [[ "$local_file_size" -gt "$s3_file_size" ]]; then
                # Upload the local file to S3, replacing the existing one.
                echo "Local file is larger, replacing the existing file in S3."
                echo "Sending $log_file to $bucket$device/$storage_date"
                uploadToS3 "$log_file" "$bucket$device/$storage_date"
            else
                echo "Local file isn't larger than the one in S3."
            fi
        else
            echo "Failed to get the size of local or S3 file."
        fi
    else
        # Upload the local file to S3, since the S3 file doesn't exist.
        echo "File not found in S3, sending file to S3."
        echo "Sending $log_file to $bucket$device/$storage_date"
        uploadToS3 "$log_file" "$bucket$device/$storage_date"
    fi
else
    echo "Local file not found."
fi


