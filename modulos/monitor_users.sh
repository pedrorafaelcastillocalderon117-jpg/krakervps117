#!/bin/bash
# Monitor de Usuarios Conectados (SSH y Dropbear)

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}           MONITOR DE USUARIOS CONECTADOS           ${NC}"
echo -e "${CYAN}====================================================${NC}"

echo -e "${GREEN}Usuario       | Conexiones activas${NC}"
echo -e "----------------------------------"

# Obtener usuarios del sistema con acceso (que no son nologin/false excepto los que creamos para túnel)
usuarios=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

for user in $usuarios; do
    # Contar procesos SSH
    conexiones_ssh=$(ps -u $user | grep sshd | wc -l)
    # Contar procesos Dropbear
    conexiones_dropbear=$(ps -u $user | grep dropbear | wc -l)
    
    total=$((conexiones_ssh + conexiones_dropbear))
    
    if [ "$total" -gt 0 ]; then
        echo -e "${YELLOW}$user${NC}          | $total"
    fi
done

echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN}Opciones:${NC}"
echo -e "[1] Bloquear un usuario por multilogin"
echo -e "[0] Volver al menú"
echo -e ""
read -p "Selecciona una opción: " opt

if [ "$opt" == "1" ]; then
    read -p "Ingresa el nombre del usuario a bloquear: " usrb
    if id "$usrb" &>/dev/null; then
        usermod -L "$usrb"
        pkill -u "$usrb"
        echo -e "${RED}El usuario $usrb ha sido bloqueado y desconectado.${NC}"
    else
        echo -e "${RED}Usuario no encontrado.${NC}"
    fi
    sleep 2
fi
