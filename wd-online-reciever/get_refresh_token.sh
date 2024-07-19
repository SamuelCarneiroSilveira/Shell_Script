#!/bin/bash

# Precisa ser rodado como sudo para cSCturar as 
# variaveis de ambiente sudo

# Usa o login e senha presente nas variaveis de 
# ambiente sudo para conseguir um token e um refresh token 
# funcional

USERNAME=${LOGIN_SCI}
PASSWORD=${PASS_SCI}

if [ -z $USERNAME ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as sudo"
        exit
    else
        echo "environment variable is not defined"
    fi
    # else
    #     echo "$USERNAME"
    #     echo "$PASSWORD"
fi

RESPONSE=$(
    curl --request POST \
    --url http://127.0.0.1:8080/SCi/token/ \
    --header 'Authorization: Bearer undefined' \
    --header 'Content-Type: SCplication/json' \
    --header 'User-Agent: insomnia/2023.5.8' \
    --data "{
        \"username\": \"$USERNAME\",
        \"password\": \"$PASSWORD\"
}" -w "\n%{http_code}")

# Extraia o código HTTP do final da resposta
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

# Remova o código HTTP da variável RESPONSE
RESPONSE=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "400" ]; then
    echo "Bad Request"
elif [ "$HTTP_CODE" == "401" ]; then
    echo "Unauthorized, check your credentials"
else
    echo "Other HTTP code: $HTTP_CODE"
    
    # extract tokens using jq
        REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.refresh')
        ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access')

        # # print (SCenas para verificação)
        # echo "$RESPONSE"
        echo "Refresh Token: $REFRESH_TOKEN"
        echo "Access Token: $ACCESS_TOKEN"

        # save tokens
        echo $REFRESH_TOKEN > ./refresh_token
        echo $ACCESS_TOKEN > ./token
fi
