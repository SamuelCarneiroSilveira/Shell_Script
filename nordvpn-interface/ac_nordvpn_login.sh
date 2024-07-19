#!/bin/bash

# Script to log on nordvpn by token
# to deslog use nordvpn persist token

# Locate the configuration file.
config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)
if [ -z "$config_txt" ]; then
    echo "Error: Configuration file not found."
    exit 1
fi

# This function retrieves configuration data from the specified file.
getConfigData() {
    grep "^$1=" "$config_txt" | cut -d'=' -f2 | tr -d '[:space:]'
}

nord_token="$(getConfigData 'token-nord')"
echo "$nord_token"

log() {
    # Verifica se está logado no NordVPN
    nordvpn_account=$(nordvpn account)

    if echo "$nordvpn_account" | grep -q "You are not logged in"; then
        
        echo "You are not logged in NordVPN. logging in..."

        if nordvpn login --token $nord_token; then
            echo "successful login"
            nordvpn set meshnet on
        else
            echo "FAIL: login fail"
        fi
    else
        echo "you are already logged in nordvpn."
    fi
}

while true; do
    
    log
    sleep 5
done