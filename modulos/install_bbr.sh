#!/bin/bash
# Instalador de TCP BBR Plus (Acelerador de red)

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}           INSTALADOR DE TCP BBR PLUS               ${NC}"
echo -e "${CYAN}====================================================${NC}"

echo -e "${GREEN}Descargando instalador de BBR Plus (Kernel optimizations)...${NC}"
cd /tmp
wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh"

if [ -f "tcp.sh" ]; then
    chmod +x tcp.sh
    echo -e "${YELLOW}Abriendo el menú interactivo de BBR.${NC}"
    echo -e "Por favor, selecciona la opción para instalar el Kernel BBR Plus (usualmente opción 2)"
    echo -e "y luego reinicia el VPS cuando te lo pida. Vuelve a ejecutar este script para activarlo."
    sleep 4
    ./tcp.sh
else
    echo -e "${RED}Hubo un error al descargar el instalador de BBR.${NC}"
    sleep 3
fi
