#!/bin/bash

# Este script verifica a conexão com a internet
# Se não houver conexão, tenta se conectar a redes Wi-Fi conhecidas
# Se ainda assim não conseguir, ativa um hotspot local

declare -A wifi_networks

# VERIFICAR PERMISSÕES E DIRETÓRIOS
if [ -z "${SC_USER}" ]; then
    echo "Erro: Script deve ser executado com sudo."
    exit 1
fi

config_txt=$(find "${SC_HOME}/shell-manager/" -type f -name "config.txt" 2>/dev/null | head -n 1)

if [ -z "$config_txt" ]; then
    echo "Erro: Arquivo de configuração não encontrado."
    exit 1
fi

# FUNÇÃO PARA CSCTURAR DADOS DO ARQUIVO DE CONFIGURAÇÃO
getConfigData() {
     grep "^$1=" "$config_txt" | cut -d'=' -f2 | tr -d '[:space:]'
}

system_wifi_driver_bash="${SC_HOME}$(getConfigData 'system_wifi_driver_bash')"
echo "path $system_wifi_driver_bash"

wifi_networks[$(getConfigData 'celular-ssid')]=$(getConfigData 'celular-password')
wifi_networks[$(getConfigData 'local-ssid')]=$(getConfigData 'local-password')
wifi_networks[$(getConfigData 'star-ssid')]=$(getConfigData 'star-password')

max_attempts=3

while true; do
    # VERIFICAR CONEXÃO COM A INTERNET
    if ping -c 1 8.8.8.8 &> /dev/null; then
        connected=true
    else
        connected=false
    fi

    if [ "$connected" = false ]; then
        # VERIFICAR WI-FI
        wifi_state=$(nmcli radio wifi)

        if [ "$wifi_state" = "enabled" ]; then
            echo "Wi-Fi está ligado, tentando conectar à uma rede Wi-Fi."

            attempt=0
            while [ $attempt -lt $max_attempts ]; do

                # CSCturar SSID e senha dos arquivos ssid.txt e senha.txt
                ssid_file="${SC_HOME}/db-manager/WifiCredentials/ssid.txt"
                password_file="${SC_HOME}/db-manager/WifiCredentials/password.txt"

                if [ -f "$ssid_file" ] && [ -f "$password_file" ]; then
                    ssid=$(cat "$ssid_file")
                    senha=$(cat "$password_file")

                    # Use as variáveis $ssid e $senha conforme necessário em seu script
                    # Por exemplo, você pode adicioná-las ao array wifi_networks
                    wifi_networks["$ssid"]="$senha"

                    echo "SSID e senha cSCturados com sucesso."
                else
                    echo "Arquivos ssid.txt e/ou senha.txt não encontrados."
                fi


                for network in "${!wifi_networks[@]}"; do
                    echo "Tentando conexão na rede $network"

                    senha="${wifi_networks[$network]}"

                    resultado=$(nmcli device wifi connect "$network" password "$senha" 2>&1)
                    if [ $? -eq 0 ]; then
                        echo "Conectado a: $network"
                        break 2  # Sai do loop externo também
                    else
                        echo "Falha ao conectar: $network"

                        if [[ $resultado == *"No Wi-Fi"* ]]; then
                            echo "Dispositivo Wi-Fi não encontrado, instalando driver"
                            bash $system_wifi_driver_bash
                        fi
                    fi
                    sleep 10s
                done

                attempt=$((attempt + 1))
            done

            # Verificar se conseguiu se conectar SCós tentativas
            if [ $attempt -ge $max_attempts ]; then
                echo "Internet não disponível SCós várias tentativas, ativando o hotspot."

                # Script para ativar o hotspot
                interface=$(ip link | grep -E 'wl[a-z0-9]+' | awk '{print $2}' | sed 's/://' | head -n 1)
                nmcli con delete hotspot
                nmcli con add type wifi ifname "$interface" con-name hotspot autoconnect no ssid samuel
                nmcli con modify hotspot ipv4.addresses 10.42.0.1/24
                nmcli con modify hotspot 802-11-wireless.mode SC 802-11-wireless.band bg ipv4.method shared
                nmcli con modify hotspot wifi-sec.key-mgmt wpa-psk
                nmcli con modify hotspot wifi-sec.psk "747U21Nh0"
                nmcli con up hotspot
                ip addr show "$interface"
            fi
        else
            echo "Ligando Wi-Fi..."
            nmcli radio wifi on
            sleep 5
        fi
    fi
    sleep 5
done