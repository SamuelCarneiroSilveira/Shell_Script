#!/bin/bash

# This function summarize a temporary cpu file and return results
# for a daily log, if there is any cpu temperature data above 80°, write
# in a log file, and if is above 90°, restart the machine

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

# Define directories and files from the configuration.
log_folder="${SC_HOME}$(getConfigData 'log')"
temp_dir="${SC_HOME}$(getConfigData 'crontab_temp')"
db_pc_log_folder="${SC_HOME}$(getConfigData 'db_pc_log_folder')"
temp_cpu_file="${SC_HOME}$(getConfigData 'cron_temporary_cpu_log_file')"

#####################
#    DEBUG
echo $log_folder
echo $temp_dir
echo $db_pc_log_folder
echo $temp_cpu_file

#####################

# This function sets up necessary directories and files.
create() {
    ensureDirectoryExists "$log_folder"
    ensureDirectoryExists "$temp_dir"
    ensureDirectoryExists "$temp_cpu_file"
    ensureDirectoryExists "$db_pc_log_folder"

    # Ensure Files exist
    touch $temp_cpu_file

    # Define storage date.
    storage_date="$(date +"%d_%m_%Y_")storage.log"

    # Check if the day's log file exists, if not, create it.
    if [ ! -f "$log_folder/$storage_date" ]; then 
        echo "Creating day log"
        touch $log_folder/$storage_date
    fi  
}

# This function checks if there are logs from multiple hours in the file.
searchDifferentTime() {
    last_line=$(tail -n 1 "$temp_cpu_file")
    last_hour=$(echo "$last_line" | cut -d 'H' -f 2 | cut -c 1-2)


    #####################
    #    DEBUG
    echo $last_hour
    echo $last_line

    #####################
    
    while IFS= read -r line; do
        line_hour=$(echo "$line" | cut -d 'H' -f 2 | cut -c 1-2)
        if [ "$last_hour" != "$line_hour" ]; then
            return 0  # Found different hours.
        fi
    done < "$temp_cpu_file"

    return 1  # All timestamps are from the same hour.
}

# This function clears all but the last line from the temporary log file.
cleanDiferentTime() {
    last_line=$(tail -n 1 "$temp_cpu_file")
    echo "$last_line" > "$temp_cpu_file"
    echo "Log file cleaned, retaining the last line: $temp_cpu_file"
}

# This function processes the logged data and calculates metrics for each hour.
calcsForHour() {
    counter=0
    higher_cpu=0
    total_cpu=0
    higher_memory=0
    total_memory=0
    higher_temp=0
    total_temp=0
    first_hour=0

    while IFS= read -r line; do
        # Extract metric values from the line.
        cpu=$(echo "$line" | cut -d '|' -f 2 | awk -F ':' '{print $2}' | tr -d ' ')
        memory=$(echo "$line" | cut -d '|' -f 3 | awk -F ':' '{print $2}' | tr -d ' ')
        temp=$(echo "$line" | cut -d '|' -f 4 | awk -F ':' '{print $2}' | sed 's/°C//')

        # Replace commas with dots for proper calculations.
        cpu=$(echo "$cpu" | tr ',' '.')
        memory=$(echo "$memory" | tr ',' '.')

        # Update total and check for highest values.
        total_cpu=$(echo "scale=2; $total_cpu + $cpu" | bc)
        total_memory=$(echo "scale=2; $total_memory + $memory" | bc)
        total_temp=$(echo "scale=2; $total_temp + $temp" | bc)

        [ $(echo "$cpu > $higher_cpu" | bc -l) -eq 1 ] && higher_cpu=$cpu
        [ $(echo "$memory > $higher_memory" | bc -l) -eq 1 ] && higher_memory=$memory
        [ $(echo "$temp > $higher_temp" | bc -l) -eq 1 ] && higher_temp=$temp

        hour=$(echo "$line" | cut -d 'H' -f 2 | cut -d ':' -f 1)

        [ $counter -eq 0 ] && first_hour=$hour
        ((counter++))
    done < <(head -n -1 "$temp_cpu_file")

    # Calculate averages.
    medium_temp=$(echo "scale=2; $total_temp / $counter" | bc)
    medium_cpu=$(echo "scale=2; $total_cpu / $counter" | bc)
    medium_memory=$(echo "scale=2; $total_memory / $counter" | bc)

    # Format and write data to the daily log.
    echo "Hour $first_hour -> Average Temp: $medium_temp °C, Higher Temp: $higher_temp °C, Average CPU: $medium_cpu %, Higher CPU: $higher_cpu %, Average Memory: $medium_memory %, Higher Memory: $higher_memory %" >> $log_folder/$storage_date

    # Here echo in .log files
    echo "$medium_temp"> $db_pc_log_folder/average_temperature.log
    echo "$higher_temp"> $db_pc_log_folder/higher_temperature.log
    echo "$medium_cpu"> $db_pc_log_folder/average_cpu.log
    echo "$higher_cpu"> $db_pc_log_folder/higher_cpu.log
    echo "$medium_memory"> $db_pc_log_folder/average_memory.log
    echo "$higher_memory"> $db_pc_log_folder/higher_memory.log

    # Here activate ts to save in db
    cd ${SC_HOME}/db-manager && npm run db_machine_data


    # Check if the temperature went too high.
    if [ $(echo "$higher_temp > 80" | bc -l) -eq 1 ]; then
        echo "Warning! CPU temperature exceeded 80°C!" >> $log_folder/$storage_date
    fi
}

# Create necessary directories and files.
create

while true; do
    # Check if there are different hours in the log file.
    if searchDifferentTime; then
        calcsForHour
        cleanDiferentTime
    fi
    sleep 5
    echo "esperando 5 seg"
done
