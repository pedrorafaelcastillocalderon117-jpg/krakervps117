#!/bin/bash
# Script de Optimización y Limpieza de RAM

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}           OPTIMIZADOR DE RAM Y CACHÉ               ${NC}"
echo -e "${CYAN}====================================================${NC}"

mem_antes=$(free -h | grep Mem | awk '{print $3}')
echo -e "${YELLOW}Memoria en uso antes de la limpieza: ${RED}$mem_antes${NC}"

# Limpiar caché de la RAM
echo -e "${GREEN}Sincronizando disco y limpiando PageCache, Dentries e Inodes...${NC}"
sync; echo 3 > /proc/sys/vm/drop_caches
sync; echo 2 > /proc/sys/vm/drop_caches
sync; echo 1 > /proc/sys/vm/drop_caches

# Limpiar archivos temporales y basura del sistema
echo -e "${GREEN}Limpiando paquetes huérfanos y temporales...${NC}"
apt-get autoremove -y &>/dev/null
apt-get clean &>/dev/null
rm -rf /tmp/*
rm -rf /var/log/syslog.1 /var/log/auth.log.1 &>/dev/null

mem_despues=$(free -h | grep Mem | awk '{print $3}')
echo -e "${YELLOW}Memoria en uso después de la limpieza: ${GREEN}$mem_despues${NC}"

echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN}Optimización completada con éxito.${NC}"
echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
