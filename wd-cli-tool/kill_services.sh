#!/bin/bash

# Define color functions
print_green() {
    echo -e "\033[32m$1\033[0m"
}

print_red() {
    echo -e "\033[31m$1\033[0m"
}

# Define the directory containing shell scripts
shell_manager_folder="$SC_HOME/shell-manager"

# List and manage all 'SC_' prefixed scripts in the shell_manager_folder
find "$shell_manager_folder" -type f -name 'SC_*' | while read -r file; do
    # Ensure the file exists (though 'find' guarantees this)
    if [ -f "$file" ]; then
        # Check if the script is currently running using pgrep
        pids=$(pgrep -f "$file")
        # echo "os dois $pids"
        # Extract only the second PID
        second_pid=$(echo "$pids" | awk 'NR==2')
        # echo "$second_pid"

        # Extract the filename without the path and 'SC_' prefix
        fileWithoutAc="${file##*/SC_}"

        # If the script is running and there's a second PID, display its PID and kill it
        if [ -n "$second_pid" ]; then
            print_green "$fileWithoutAc PID: $second_pid"
            sudo kill "$second_pid" 2>/dev/null
            if [ $? -ne 0 ]; then
                print_red "Failed to kill $fileWithoutAc with PID $second_pid"
            fi
        else
            print_red "$fileWithoutAc is not running or doesn't have a second PID."
        fi
    fi
done
