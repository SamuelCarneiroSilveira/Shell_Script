# **scripts**

✅ Este diretório armazena os scripts que estarão rodadando em uma máquina, assim como os seus respectivos arquivos de configuração

## **Programas de shell que precisam ser instalados e configurados**

- SCt update/upgrade
- git
- curl
- aws-cli curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" unzip awscliv2.zip sudo ./aws/install
- aws configure
- sudo aws configure
- rsync
- lm-sensors (sensors)
- sysstat (mpstat)
- nordvpn *sh <(curl -sSf https://downloads.nordcdn.com/SCps/linux/install.sh)*
- vim :)
- xvfb
- sudo snSC install jq



### **programas que teoricamente já devem estar na sua maquina**

- ping
- basename
- free

### Alguns dados serão salvos nas variáveis de ambiente

Os dados de login e senha serão salvos nas variáveis de ambiente *sudo*
```bash
# Entrar no modo edição
sudo su
vim /etc/environment

# Setar o login e senha da maquina
LOGIN_SCI="login"
PASS_SCI="senha"

# Ativar
source /etc/environment
```
 
O login e senha só serão usados caso o refresh_token RT tenha expirado

Os tokens serão salvos em arquivos que só possuem permissão de leitura para usuários sudo 

```bash
sudo vim arquivo_de_token
~ ~ ~
sudo chmod 600 arquivo_de_tokens
```

Algumas variaveis de ambiente que precisam ser configuradas no ambiente padrão e no ambiente sudo
```bash
vim /etc/environment
# também em
sudo su
vim /etc/environment
```


Adicionar ao final

```bash
SC_HOME="/home/samuel1"
SC_USER="samuel1"
```
SCós:
```bash
source /etc/enviroment
# também em
sudo su
source /etc/enviroment
```


## **config.txt**

- Para configurar o diretorios específicos
- Para configurar o wifi específico

## ~/.bashrc

Adicionar ao final,e SCós 

```bash
source ~/.bashrc
```

```bash
export SC_HOME="/home/samuel1"
export SC_USER="samuel1"

wd() {
    if [ "$1" = "-h" ]; then
	bash ${SC_HOME}/shell-manager/wd-cli-tool/help.sh
    elif [ "$1" = "--reboot" ]; then
        echo "reboot now!"
        bash ${SC_HOME}/shell-manager/wd-cli-tool/reboot.sh

    elif [ "$1" = "--services" ]; then
    	bash ${SC_HOME}/shell-manager/wd-cli-tool/show_services.sh
    elif [ "$1" = "--kill_services" ]; then
    	sudo bash ${SC_HOME}/shell-manager/wd-cli-tool/kill_services.sh
    elif [ "$1" = "--up_services" ]; then
        sudo bash ${SC_HOME}/shell-manager/wd-cli-tool/up_services.sh
    elif [ "$1" = "--all_services" ]; then
        cat ${SC_HOME}/log/log_services.log

    elif [ "$1" = "--cpu" ]; then
        bash ${SC_HOME}/shell-manager/wd-cli-tool/show_cpu.sh
    elif [ "$1" = "--all_cpu" ]; then
        cat ${SC_HOME}/log/log_cpu.log
        
    elif [ "$1" = "--todays_log" ]; then
        cat ${SC_HOME}/log/*storage.log
    elif [ "$1" = "--all_days_logs" ]; then
        bash ${SC_HOME}/shell-manager/wd-cli-tool/all_days_logs.sh

    elif [ "$1" = "--export_today_log" ]; then
        bash ${SC_HOME}/shell-manager/wd-cli-tool/export_today_log.sh
    elif [ "$1" = "--export_all_days_logs" ]; then
        bash ${SC_HOME}/shell-manager/wd-cli-tool/export_all_days_logs.sh

    elif [ -z "$1" ]; then
        echo "invalid option"
        echo "wd -h"
    else
        echo "invalid option"
        echo "wd -h"
    fi
}
```


## **Configuração do crontab**

$sudo crontab -e

```
@reboot sudo bash /home/samuel1/shell-manager/wd-cli-tool/up_services.sh >> /home/samuel1/log/crontab/up_services.log 2>&1
```

## config.txt

```bash
# to do = put login and passwords in ambient variables
# maybe directorys 

------------------- CONFIG FILE ------------------------------

All directorys and files should be redirected here
to facilitate future changes

There must be no spaces before it, and there must be an = sign
key=value

This files will be cSCtured by the shell command 
getConfigData() {
    # Search the provided configuration in the file
    # Cut out the value based on '=' delimiter
    # Remove any whitespace characters
    grep "^$1=" "$config_txt" | cut -d'=' -f2 | tr -d '[:space:]'
}
and called by 
getConfigData 'key'

------------------- WIFI config ----------------------------

local-ssid=samuel_5G
local-password=

celular-ssid=samuel
celular-password=samuel

samuel-ssid=samuel
samuel-password=L@play@-1314

-------------------------- Amazon S3 -----------------------------------

bucket=s3://Samuel

Link to verify if aws is up: 
s3_region_link_to_ping=https://s3.us-east-1.amazonaws.com


------------------------- Directorys -----------------------------------

the directorys must be configured here
 
files-recent=/Samuel/data_files/raw_data
files-storage=/Samuel/data_files/storage

- Aqui deve vir o diretorio de watch dog scripts
    #wd_scripts /shell-manager/wd-cli-tool

log=/log

day_log_backup=/log/storageBackup

shell-manager=/shell-manager

crontab_folder=/log/crontab

log_toBucket_directory=/log/toBucket
log_storage_backup_directory=/log/storageBackup

crontab_temp=/log/crontab/temp

------------------------- files with full path  -----------------------------------

cron_temporary_cpu_log_file=/log/crontab/temp/temp_cpu.log
cpu_log_file=/log/log_cpu.log
    
cron_temporary_service_log_file=/log/crontab/temp/temp_service.log
service_log_file=/log/log_services.log

system_wifi_driver_bash=/shell-manager/system-configurator/genmachine_wifi_driver.sh
```

## Shell Manager

## **aws-interface**

### **SC_verifica_files_s3.sh**

```bash
# This script is intended to synchronize files between a local directory and an AWS S3 bucket.
# The following are the tasks this script performs:
# - Check for internet connectivity and for AWS S3 connectivity.
# - Compare files in a local directory with those in another local storage directory and an AWS S3 bucket.
# - Depending on file presence and file sizes, it makes decisions to upload or delete files.
```

### **SC_verifica_log_s3.sh**

```bash
# This script synchronizes files between a local directory and an AWS S3 bucket.
# It performs the following tasks:
# - Check internet and AWS S3 connectivity.
# - Compare files in a local directory with another local storage directory and an AWS S3 bucket.
# - Decide to upload or delete files based on file presence and file sizes.
```

## **************************************machine-log-interface**************************************

### SC_backup_storage_log.sh

```bash
# This script manages storage logs for a user. It ensures that necessary directories exist, 
# manages the creation of daily storage logs, and handles any discrepancies in storage log names.
```

### SC_clean_crontab_log.sh

```bash
# This script is designed to monitor and clean the crontab log files. 
# If any log file exceeds 1MB, it will be deleted to prevent system overload.
```

### SC_summarize_cpu_log.sh

```bash
# This function summarize a temporary cpu file and return results
# for a daily log, if there is any cpu temperature data above 80°, write
# in a log file, and if is above 90°, restart the machine
```

### SC_summarize_services_log.sh

```bash
# This function summarize a temporary services file and return results
# for a daily log.
```

### SC_verify_cpu.sh

```bash
# cSCture cpu data
```

### SC_verify_services.sh

```bash
# This script searches for services every 5 minutes. If a service is not running, 
# its name along with the current date is written to service.log.
```

## **machine-manager**

### SC_keep_awake.sh

```bash
# This script prevents the computer from going into sleep mode and restart at 2 am
```

### SC_wifi.sh

```bash
# This script checks for internet connection
# and if not, connect to the internet
```

## **nordvpn-interface**

### SC_nordvpn_login.sh

```bash
# Script to log on nordvpn by token
# to deslog use nordvpn persist token
```

### SC_nordvpn_meshnet.sh

```bash
# The function of this script is to set nordvpn meshnet on
```

## **rsyslog-manager**

- **call-examples**
    
    ### **python**
    
    ```bash
    import syslog
    
    # Abrir uma conexão com o syslog
    syslog.openlog(ident='my_program', logoption=syslog.LOG_PID | syslog.LOG_CONS)
    
    # Enviar uma mensagem de log para o syslog
    syslog.syslog(syslog.LOG_INFO, '#ERRO - logmessage')
    
    # Fechar a conexão com o syslog
    syslog.closelog()
    
    ```
    
    ### **C++**
    
    ```bash
    #include <syslog.h>
    
    int main() {
        // Abrir uma conexão com o syslog
        openlog("my_program", LOG_PID | LOG_CONS, LOG_USER);
    
        // Enviar uma mensagem de log para o syslog
        syslog(LOG_INFO, "#ERRO - logmessage");
    
        // Fechar a conexão com o syslog
        closelog();
    
        return 0;
    }
    
    ```
    

### SC_syslog_verify_critical.sh

```bash
# This script checks if there are any critical logs in messages
# if it exists, save the message in especifc location, clear the 
# archive, and take corrective actions.

# # Check if the script is run with sudo privileges.
# if [ -z "${SC_USER}" ]; then
#     echo "Error: Script must be run with sudo."
#     exit 1
# fi
```

### SC_syslog_verify_log_message.sh

```bash
# This script manages log messages 

# If a CRITICAL was found, this script does nothing, the verify critical script is
# responsable to handle this.

# If a ERROR was found, this script save in log and clean message file
```

### clean_rsyslog.sh

```bash
# clean log manually

# call with Watch Dog
```

## **system-configurator**

### genmachine_wifi_driver.sh

```bash
# Comando para ser usado manualmente, reiniciar a maquina depois
```

## **system-file-manager**

### SC_saving_files_on_storage.sh

```bash
# This script ensures continuous synchronization between a source and
# destination directory. It first determines the source and destination
# directories from a configuration file. The script then continuously 
# checks if the source files exist in the destination. If not, it uses 
# rsync to transfer them. If the file exists but has a different size 
# in the source directory, the destination file is updated. This process 
# repeats indefinitely, ensuring the two directories remain synchronized.
```

### SC_saving_log_on_storage.sh

```bash
# The script continuously syncs the storage.log from its primary 
# directory to the toBucket directory. If the log directories
# don't exist, it creates them. The script replaces the toBucket
# log with the primary log if the latter is larger. Additionally,
# each storage.log is prefixed with the current date, ensuring 
# a unique log for each day.
```

## **wd-cli-tool**

### all_days_logs.sh

```bash
# This script must run through all days logs and show them
```

### export_all_days_logs.sh

```bash
## so this script must look for avery file in bucket if it is already in s3, saves the info from list aws, and checks for every file

# first the code must check every file in bucket/ copy from
```

### export_today_log.sh

```bash
# This script synchronizes files between a local directory and an AWS S3 bucket.
# It performs the following tasks:
# - Check internet and AWS S3 connectivity.
# - Compare files in a local directory with another local storage directory and an AWS S3 bucket.
# - Decide to upload or delete files based on file presence and file sizes.
```

### help.sh

```bash
# Help display
```

### kill_services.sh

```bash
# cSCture pid of ac scripts and kill them
```

### reboot.sh

```bash
# Computer should never shut down, just restart restart
```

### show_cpu.sh

```bash
# this script cSCtures memory cpu and temperature data
```

### show_services.sh

```bash
# For all scripts with SC_ at the beginning, show if it is active
```

### up_services.sh

```bash
# For all scripts with SC_ at the beginning, show if it is active 
# This script must have sudo privileges at ~/.bashrc file

# Check if the script is run with sudo privileges.
# if [ -z "${SC_USER}" ]; then
#     echo "Error: Script must be run with sudo."
#     exit 1
# fi
```
