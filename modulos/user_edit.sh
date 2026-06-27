#!/bin/bash
# Módulo para editar usuarios

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}                  EDITAR USUARIO                    ${NC}"
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
read -p " ❯ Ingresa el número del usuario a editar (0 para cancelar): " num

if [ "$num" == "0" ]; then
    exit 0
fi

if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -gt 0 ] && [ "$num" -le "${#arr_usuarios[@]}" ]; then
    username="${arr_usuarios[$((num-1))]}"
    
    echo -e "${CYAN}--- Editando a: ${YELLOW}$username${CYAN} ---${NC}"
    
    # Editar Contraseña
    read -p "Nueva Contraseña (dejar en blanco para no cambiar): " new_pass
    if [ -n "$new_pass" ]; then
        echo "$username:$new_pass" | chpasswd
        echo -e "${GREEN}Contraseña actualizada.${NC}"
    fi
    
    # Editar Validez
    read -p "Días extra a sumar a la validez actual (dejar en blanco para no cambiar): " new_dias
    if [[ "$new_dias" =~ ^[0-9]+$ ]]; then
        # Obtener fecha de expiracion actual
        current_exp=$(chage -l "$username" | grep "Account expires" | cut -d: -f2 | xargs)
        if [ "$current_exp" == "never" ] || [ -z "$current_exp" ]; then
            # Si no tenia expiracion, calcular a partir de hoy
            expdate=$(date "+%F" -d "+$new_dias days")
        else
            # Sumar a la fecha actual
            expdate=$(date "+%F" -d "$current_exp + $new_dias days" 2>/dev/null)
            if [ -z "$expdate" ]; then
                # Si falla por formato, usar la fecha de hoy
                expdate=$(date "+%F" -d "+$new_dias days")
            fi
        fi
        chage -E "$expdate" "$username"
        echo -e "${GREEN}Nueva fecha de expiración: $expdate${NC}"
    fi
    
    # Editar Límite de IPs
    current_limit="1"
    if [ -f "/etc/script_vps/limites/$username" ]; then
        current_limit=$(cat "/etc/script_vps/limites/$username")
    fi
    read -p "Nuevo Límite de IPs [Actual: $current_limit] (dejar en blanco para no cambiar): " new_limit
    if [ -n "$new_limit" ] && [[ "$new_limit" =~ ^[0-9]+$ ]]; then
        echo "$new_limit" > "/etc/script_vps/limites/$username"
        echo -e "${GREEN}Límite de IPs actualizado a: $new_limit${NC}"
    fi

    echo -e "${GREEN}Cambios guardados correctamente.${NC}"
else
    echo -e "${RED}Número de usuario inválido.${NC}"
fi

echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
