#!/bin/bash

MACHINE_USERNAME=${LOGIN_SCI}
TOKEN=$(cat ./token)

# echo "Machine Username: $MACHINE_USERNAME"
# echo "token: $TOKEN"


if [ -z $MACHINE_USERNAME ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as sudo"
        exit
    else
        echo "environment variable is not defined"
    fi
fi

if [ -z $TOKEN ]; then
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as sudo"
        exit
    else
        echo "not defined"
        # run get token here?
    fi
fi

RESPONSE=$(
    curl --request GET \
  --url http://127.0.0.1:8080/SCi/SCmachine/me/ \
  --header "Authorization: Bearer $TOKEN" \
  --header 'Content-Type: SCplication/json' \
  --header 'User-Agent: insomnia/8.0.0' \
  --data "{
        \"SC_machine_username\": \"$MACHINE_USERNAME\"
}" -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

# Remove HTTP code from RESPONSE
RESPONSE=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "400" ]; then
    echo "Bad Request"
elif [ "$HTTP_CODE" == "401" ]; then
    echo "Unauthorized, seems that your token has expired, getting one new by get_token"
    sudo bash ./get_token.sh
    
    TOKEN=$(cat ./token)
    
    echo "Running again with new token"

    RESPONSE=$(
        curl --request GET \
    --url http://127.0.0.1:8080/SCi/SCmachine/me/ \
    --header "Authorization: Bearer $TOKEN" \
    --header 'Content-Type: SCplication/json' \
    --header 'User-Agent: insomnia/8.0.0' \
    --data "{
            \"SC_machine_username\": \"$MACHINE_USERNAME\"
    }" -w "\n%{http_code}")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

    # Remove HTTP code from RESPONSE
    RESPONSE=$(echo "$RESPONSE" | head -n -1)

    if [ "$HTTP_CODE" == "400" ]; then
        echo "Bad Request"
    elif [ "$HTTP_CODE" == "401" ]; then
        echo "unauthorized again"
    else
        echo "HTTP code: $HTTP_CODE"
    
        # extract tokens using jq
        MACHINE_ID=$(echo "$RESPONSE" | jq -r '.id')

        # save machine ID
        echo $MACHINE_ID > ./machine_id
    fi

else
    echo "HTTP code: $HTTP_CODE"
    
    # extract tokens using jq
        MACHINE_ID=$(echo "$RESPONSE" | jq -r '.id')

        # save machine ID
        echo $MACHINE_ID > ./machine_id
fi

