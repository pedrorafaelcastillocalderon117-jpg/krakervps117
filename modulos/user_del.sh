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

mapfile -t arr_usuarios < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

if [ ${#arr_usuarios[@]} -eq 0 ]; then
    echo -e "${YELLOW}No hay usuarios VPN creados en el sistema.${NC}"
    echo -e "${CYAN}====================================================${NC}"
    read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
    exit 0
fi

echo -e "${WHITE}Lista de usuarios:${NC}"
for i in "${!arr_usuarios[@]}"; do
    echo -e " ${GREEN}[$((i+1))]${NC} ${arr_usuarios[$i]}"
done
echo -e ""
read -p " ❯ Ingresa el número del usuario a eliminar (0 para cancelar): " num

if [ "$num" == "0" ]; then
    exit 0
fi

if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -gt 0 ] && [ "$num" -le "${#arr_usuarios[@]}" ]; then
    username="${arr_usuarios[$((num-1))]}"
    
    # Eliminar procesos del usuario
    pkill -u "$username"
    
    # Eliminar regla de iptables de consumo y archivo de límite
    iptables -D OUTPUT -m owner --uid-owner "$username" -j ACCEPT 2>/dev/null
    rm -f "/etc/script_vps/limites/$username"
    
    # Limpiar configuracion de OpenSSH Banner
    rm -f "/etc/ssh/sshd_config.d/banner_${username}.conf"
    rm -f "/etc/script_vps/banners/$username"
    systemctl reload sshd 2>/dev/null

    userdel -r "$username" 2>/dev/null
    echo -e "${GREEN}El usuario $username ha sido eliminado exitosamente.${NC}"
else
    echo -e "${RED}Número de usuario inválido.${NC}"
fi

echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
