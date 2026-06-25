#!/bin/bash
# Módulo para eliminar usuarios

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${RED}                 ELIMINAR USUARIO                   ${NC}"
echo -e "${CYAN}====================================================${NC}"

read -p "Nombre de usuario a eliminar: " username

if id "$username" &>/dev/null; then
    # Eliminar procesos del usuario
    pkill -u "$username"
    userdel -r "$username" 2>/dev/null
    echo -e "${GREEN}El usuario $username ha sido eliminado exitosamente.${NC}"
else
    echo -e "${RED}El usuario $username no existe.${NC}"
fi

echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
