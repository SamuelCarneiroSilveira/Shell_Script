#!/bin/bash

# For all scripts with SC_ at the beginning, show if it is active 
# This script must have sudo privileges at ~/.bashrc file

# Check if the script is run with sudo privileges.
# if [ -z "${SC_USER}" ]; then
#     echo "Error: Script must be run with sudo."
#     exit 1
# fi

echo "$USER"

## Caso ros pare
# source ${SC_HOME}/catkin_ws/devel/setup.bash

# Up ros
  
source /opt/ros/noetic/setup.bash
source /${SC_HOME}/catkin_ws/devel/setup.bash
roscore &
rosrun ros_esp serialize_display_number.py &

# Up SCi's
cd /${SC_HOME}/db-manager && npx prisma studio &
node /${SC_HOME}/db-manager/index.js &
node /${SC_HOME}/db-manager/ros_collect.js &


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
# Locate the configuration file.

# config_txt=$(find "samuel1/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)
config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)
# echo "Searching in: ${SC_HOME}/shell-manager/"
echo "Searching in: $config_txt"
if [ -z "$config_txt" ]; then
    echo "an Error: Configuration file not found."
    exit 1
fi


# Change color functions
print_green() {
    echo -e "\033[32m$1\033[0m"
}

print_red() {
    echo -e "\033[31m$1\033[0m"
}

# define directory shell_manager_folder
shell_manager_folder="$(echo ${SC_HOME}$(getConfigData 'shell-manager'))"
crontab_folder="$(echo ${SC_HOME}$(getConfigData 'crontab_folder'))"
ensureDirectoryExists "$shell_manager_folder"

#DEBUG
# echo "shell folder path $shell_manager_folder"
# echo "config file path $shell_manager_folder"

# sudo bash ${SC_HOME}/shell-manager/rsyslog-manager/SC_syslog_verify_critical.sh 2>&1 &

# sudo bash ${SC_HOME}/shell-manager/rsyslog-manager/SC_syslog_verify_log_message.sh

find "$shell_manager_folder" -type f -name 'SC_*' | while read -r file; do
    # verify if there is any file
    if [ -f "$file" ]; then
        #define a log file name based on the current scripts name
        log_file="$crontab_folder/$(basename "$file").log"
        
        # Runs pgrep -f command with file full name 
        result=$(pgrep -f "$file")
        
        fileWithoutAc="${file##*/SC_}"

        if [ -n "$result" ]; then
            print_green "$fileWithoutAc PID: $result"
        else
            print_red "Rebooting $fileWithoutAc..."
            echo "Rebooting $file"
            sudo bash $file > "$log_file" 2>&1 &
            # sudo bash $file > /dev/null 2>&1 &
            # Restart the script, and throw it to the background  
        fi
    fi
done
