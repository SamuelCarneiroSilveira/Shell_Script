#!/bin/bash


# Usa o refresh token atual para atualizar o token

REFRESH_TOKEN=$(cat ./refresh_token)
echo "refresh token atual: $REFRESH_TOKEN"


if [ -z $REFRESH_TOKEN ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as sudo"
        exit
    else
        echo "Não definida"
    fi
fi
# CSCtura a resposta e o código HTTP
RESPONSE=$(curl --request POST \
    --url http://127.0.0.1:8080/SCi/token/refresh/ \
    --header 'Content-Type: SCplication/json' \
    --header 'User-Agent: insomnia/2023.5.8' \
    --data "{
        \"refresh\": \"$REFRESH_TOKEN\"
}" -w "\n%{http_code}")

# Extraia o código HTTP do final da resposta
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

# Remova o código HTTP da variável RESPONSE
RESPONSE=$(echo "$RESPONSE" | head -n -1)

echo "resposta completa: $RESPONSE"

if [ "$HTTP_CODE" == "400" ]; then
    echo "Bad Request"
elif [ "$HTTP_CODE" == "401" ]; then
    echo "Unauthorized, seems that your refresh token has expired, getting one new by get_refresh_token"
    
    sudo bash ./get_refresh_token.sh
    
    TOKEN=$(cat ./token)
    REFRESH_TOKEN=$(cat ./refresh_token)
    echo "new token $TOKEN"
    echo "new token $REFRESH_TOKEN"
    
else
    echo "Other HTTP code: $HTTP_CODE"
    
    ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r '.access')
    echo "token de acesso: $ACCESS_TOKEN"
    echo $ACCESS_TOKEN > ./token
fi

