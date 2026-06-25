#!/bin/bash
# Instalador de Dropbear

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}               INSTALADOR DE DROPBEAR               ${NC}"
echo -e "${CYAN}====================================================${NC}"

# Instalación
echo -e "${GREEN}Instalando Dropbear...${NC}"
apt-get install dropbear -y &>/dev/null

echo -e "${YELLOW}Configuración de Puertos para Dropbear${NC}"
read -p " Puerto principal (ej. 80): " drop_port
if [ -z "$drop_port" ]; then drop_port=80; fi

read -p " Puertos extra separados por espacio (o presiona ENTER para omitir, ej. 109 110): " drop_extra
extra_args=""
if [ -n "$drop_extra" ]; then
    for p in $drop_extra; do
        extra_args="$extra_args -p $p"
    done
fi

# Configuración optimizada para máxima velocidad
cat <<EOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=$drop_port
DROPBEAR_EXTRA_ARGS="$extra_args"
DROPBEAR_BANNER=""
EOF

# Detener servicios web por si ocupan el puerto 80
systemctl stop apache2 nginx &>/dev/null
systemctl disable apache2 nginx &>/dev/null

# Reiniciar servicio
systemctl restart dropbear
systemctl enable dropbear &>/dev/null

echo -e "${GREEN}Dropbear ha sido instalado y configurado en el puerto $drop_port.${NC}"
echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
