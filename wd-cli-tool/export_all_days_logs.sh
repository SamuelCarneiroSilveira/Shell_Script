#!/bin/bash

## so this script must look for avery file in bucket if it is already in s3, saves the info from list aws, and checks for every file

# first the code must check every file in bucket/ copy from 



# This script must run through all days logs and show the basename of the files


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
log_storage_backup_directory="${SC_HOME}$(getConfigData 'log_storage_backup_directory')"
bucket="$(getConfigData 'bucket')"
device="/${SC_USER}"

ensureDirectoryExists "$day_log_backup_folder"
ensureDirectoryExists "$log_storage_backup_directory"

#DEBUG
# echo "Log directory: $log_toBucket_directory"
# echo "Bucket: $bucket"
# echo "Device: $device"
# echo "Bucket Device Directory: $bucket$device"

# log_file="$log_toBucket_directory/$storage_date"
#DEBUG
# echo "Log file: $log_file"

# Function to upload file to S3.
uploadToS3() {
    local local_file="$1"
    local s3_path="$2"
    echo "Sending $local_file to $s3_path"
    sudo aws s3 cp "$local_file" "$s3_path"
}

s3_file_list=$(sudo aws s3 ls "$bucket$device/")

#DEBUG
# echo "aqui eles $s3_file_list"

verifyAllLogs() {
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
        #DEBUG
        # echo "_______________________ $(basename $log_file) _______________________"
  
        if ! echo "$s3_file_list" | grep -q "$(basename $log_file)"; then
            echo "The file $(basename $log_file) isn't in s3 bucket!"

            # Here the logic to export
            log_file="$log_storage_backup_directory/$(basename $log_file)"
            cleanBucketName="$(echo "$bucket$device" | awk -F '//' '{print $2}' | awk -F '/' '{print $1}')"
            #DEBUG
            # echo " log file $log_file"
            # echo " clean bucket name $cleanBucketName"

             # Upload the local file to S3, replacing the existing one.
                # echo "Sending $(basename $log_file) to $bucket$device/$(basename $log_file)"
                uploadToS3 "$log_file" "$bucket$device/$(basename $log_file)"




        fi
        # echo "localização e nome do arquivo $day_log_backup_folder/$log_file " 
    done
}


verifyAllLogs



# # THIS PART MUST RUN FOR EVERY SCRIPT
# #################################################
# storage_date="$(date +"%d_%m_%Y_")storage.log"
# log_file="$log_toBucket_directory/$storage_date"

# # Check if the local file exists.
# if [ -f "$log_file" ]; then
#     echo "The file $log_file exists"
#     # Get the size of the local file.
#     local_file_size=$(stat -c "%s" "$log_file")
#     echo "Local file size is $local_file_size"
#     # Check if the file exists in S3.
#     if sudo aws s3 ls "$bucket$device/$storage_date" >/dev/null 2>&1; then
#         # Get the size of the file in S3.
#         echo "File found in S3"
        
        
#         cleanBucketName="$(echo "$bucket$device" | awk -F '//' '{print $2}' | awk -F '/' '{print $1}')"
#         s3_file_size="$(aws s3SCi head-object --bucket "$cleanBucketName" --key "${SC_USER}/$storage_date" --query 'ContentLength' --output text)"
#         echo "File size in S3 is $s3_file_size"
        
        
        
#         # Check if variables are not empty.
#         if [ -n "$local_file_size" ] && [ -n "$s3_file_size" ]; then
#             # Compare file sizes.
#             if [[ "$local_file_size" -gt "$s3_file_size" ]]; then
#                 # Upload the local file to S3, replacing the existing one.
#                 echo "Local file is larger, replacing the existing file in S3."
#                 echo "Sending $log_file to $bucket$device/$storage_date"
#                 uploadToS3 "$log_file" "$bucket$device/$storage_date"
#             else
#                 echo "Local file isn't larger than the one in S3."
#             fi
#         else
#             echo "Failed to get the size of local or S3 file."
#         fi
#     else
#         # Upload the local file to S3, since the S3 file doesn't exist.
#         echo "File not found in S3, sending file to S3."
#         echo "Sending $log_file to $bucket$device/$storage_date"
#         uploadToS3 "$log_file" "$bucket$device/$storage_date"
#     fi
# else
#     echo "Local file not found."
# fi
# ###############################






# now the script must cSCture all files in bucket
















