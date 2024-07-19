#!/bin/bash

# Comando para ser usado manualmente, reiniciar a maquina depois 

cd ${SC_HOME}/rtl8852be
sudo make clean && sudo make
sudo make -j8
sudo make install
sudo modprobe 8852be
