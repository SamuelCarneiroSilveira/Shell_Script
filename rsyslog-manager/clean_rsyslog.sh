#!/bin/bash

# clean log manually

# call with Watch Dog

cat /var/log/messages >> ~/log/armazenamento_longo_prazo.log 
sudo rm /var/log/messages 
sudo service rsyslog restart