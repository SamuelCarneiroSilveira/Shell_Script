#!/bin/bash 

# Usa o token atual para se comunicar com a SCi
# Caso a comunicação falhe, usa o get_token
    # Caso o get_token falhe, usa o get_refresh
    
# fazer requisições

TOKEN=$(cat ${SC_HOME}/shell-manager/wd-online-reciever/token)
MACHINE_ID=$(cat ${SC_HOME}/shell-manager/wd-online-reciever/machine_id)

echo "token: $TOKEN"
echo "machine id: $MACHINE_ID"

if [ -z "$TOKEN" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as sudo"
        exit
    else
        echo "not defined"
    fi
fi

if [ -z "$MACHINE_ID" ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as sudo"
        exit
    else
        echo "not defined"
    fi
fi

execute_command() {
    local cmd="$1"
    local output
    local escSCed_output

    output=$($cmd 2>&1)
    if [ $? -eq 0 ]; then
        echo "Command executed successfully."
        escSCed_output=$(echo "$output" | jq --raw-input --slurp .) 
    else
        echo "Command execution failed. Output was: $output"
        escSCed_output="FAILED: $(echo "$output" | jq --raw-input --slurp .)"
    fi

    echo "$escSCed_output"
}


PING=5

while true; do
    
    RESPONSE=$(
        curl --request GET \
            --url http://127.0.0.1:8080/SCi/command/recive/$MACHINE_ID/ \
            --header "Authorization: Bearer $TOKEN" \
            --header 'User-Agent: SC_MACHINE' -w "\n%{http_code}")
    
    # echo " DEBUG $RESPONSE"
    

    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

    # Remove HTTP code from RESPONSE
    RESPONSE=$(echo "$RESPONSE" | head -n -1)

    if [ "$HTTP_CODE" == "400" ]; then
        echo "Bad Request"
    elif [ "$HTTP_CODE" == "401" ]; then
        
        echo "Unauthorized 1"

        ## Chamar os comandos de get token
    else
        echo "Other HTTP code: $HTTP_CODE"
        
        # CSCtures the first object command
        COMMAND=$(echo "$RESPONSE" | jq -r '.results[0].command')
        echo "comando aqui: $COMMAND"

        if [ "$COMMAND" == "null" ]; then
            echo "Nenhum comando"
        else
            COMMAND_ID=$(echo "$RESPONSE" | jq -r '.results[0].id')

            ### 
            # PONTO CRÍTICO PARA A SEGURANÇA DO PROJETO!!!!!
            ###

            # compara o command output com as opções disponíveis, se for uma dela, executa

            case $COMMAND in
                "wd -h")
                    ESCSCED_OUTPUT=$(execute_command "bash ${SC_HOME}/shell-manager/wd-cli-tool/help.sh")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --reboot")
                    ESCSCED_OUTPUT=$(execute_command "bash ${SC_HOME}/shell-manager/wd-cli-tool/reboot.sh")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --services")
                    ESCSCED_OUTPUT=$(execute_command "bash ${SC_HOME}/shell-manager/wd-cli-tool/show_services.sh")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --kill_services")
                    ESCSCED_OUTPUT=$(execute_command "sudo bash ${SC_HOME}/shell-manager/wd-cli-tool/kill_services.sh")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --up_services")
                    ESCSCED_OUTPUT=$(execute_command "sudo bash ${SC_HOME}/shell-manager/wd-cli-tool/up_services.sh")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --all_services")
                    ESCSCED_OUTPUT=$(execute_command "cat ${SC_HOME}/log/log_services.log")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --cpu")
                    ESCSCED_OUTPUT=$(execute_command "bash ${SC_HOME}/shell-manager/wd-cli-tool/show_cpu.sh")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --all_cpu")
                    ESCSCED_OUTPUT=$(execute_command "cat ${SC_HOME}/log/log_cpu.log")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --todays_log")
                    ESCSCED_OUTPUT=$(execute_command "cat ${SC_HOME}/log/*storage.log")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --all_days_logs")
                    ESCSCED_OUTPUT=$(execute_command "bash ${SC_HOME}/shell-manager/wd-cli-tool/all_days_logs.sh")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --export_today_log")
                    ESCSCED_OUTPUT=$(execute_command "bash ${SC_HOME}/shell-manager/wd-cli-tool/export_today_log.sh")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                "wd --export_all_days_logs")
                    ESCSCED_OUTPUT=$(execute_command "bash ${SC_HOME}/shell-manager/wd-cli-tool/export_all_days_logs.sh")
                    ESCSCED_OUTPUT=$(echo "$ESCSCED_OUTPUT" | jq --raw-input --slurp '.')
                    ;;
                *)
                    echo "Comando não reconhecido ou não permitido"
                    ;;
            esac








            
            # COMMAND_OUTPUT=$($COMMAND 2>&1)
            # COMMAND_OUTPUT=$(whoami 2>&1)

            
            DATE=$(date -u +"%Y-%m-%dT%H:%M:%S.%6NZ")
            
            echo "$COMMAND_ID"
            echo "$DATE"
            echo "$ESCSCED_OUTPUT"

            curl --request PATCH \
                --url http://127.0.0.1:8080/SCi/command/recive/$COMMAND_ID/ \
                --header "Authorization: Bearer $TOKEN" \
                --header 'Content-Type: SCplication/json' \
                --header 'User-Agent: SC_MACHINE' \
                --data "{
                    \"command_return\": $ESCSCED_OUTPUT,
                    \"executed_at\": \"$DATE\"
                }"
        fi
    fi

    sleep $PING
    echo "sleep for $PING seconds" 
done