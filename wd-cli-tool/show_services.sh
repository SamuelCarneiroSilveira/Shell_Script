#!/bin/bash

# For all scripts with SC_ at the beginning, show if it is active 

# Change color functions
print_green() {
    echo -e "\033[32m$1\033[0m"
}

print_red() {
    echo -e "\033[31m$1\033[0m"
}

# Defines shell_manager_folder directory
shell_manager_folder="$SC_HOME/shell-manager"

# To all ac files in shell_manager_folder
find "$shell_manager_folder" -type f -name 'SC_*' | while read -r file; do
    # Verify if there is any shell_manager_folder
    if [ -f "$file" ]; then
        # Runs pgrep -f command with file full name 
        result=$(pgrep -f "$file")
        fileWithoutAc="${file##*/SC_}"

        if [ -n "$result" ]; then
            print_green "$fileWithoutAc PID: $result"
        else
            print_red "$fileWithoutAc"
        fi
    fi
done
