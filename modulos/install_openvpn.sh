#!/bin/bash
# Instalador de OpenVPN (Basado en scripts estándar de comunidad)

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}              INSTALADOR DE OPENVPN                 ${NC}"
echo -e "${CYAN}====================================================${NC}"

echo -e "${GREEN}Descargando instalador automatizado de OpenVPN...${NC}"
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

echo -e "${YELLOW}Se abrirá el asistente de OpenVPN.${NC}"
echo -e "Puedes dejar las opciones por defecto presionando ENTER."
sleep 3

# Ejecutar el instalador
./openvpn-install.sh

# Limpieza
rm openvpn-install.sh

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN}Instalación de OpenVPN finalizada.${NC}"
echo -e "Los perfiles .ovpn se generarán en el directorio actual o en /root/."
echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
