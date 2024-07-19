#!/bin/bash

# Computer should never shut down, just restart restart

# Check if the script is run with sudo privileges.
if [ -z "${SC_USER}" ]; then
    echo "Error: Script must be run with sudo."
    exit 1
fi


echo "rebooting..."
sudo shutdown -r now 
