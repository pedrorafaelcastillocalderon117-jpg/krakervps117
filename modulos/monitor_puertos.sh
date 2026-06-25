#!/bin/bash
# Monitor de Puertos Abiertos

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}           MONITOR DE PUERTOS Y SERVICIOS           ${NC}"
echo -e "${CYAN}====================================================${NC}"

echo -e "${GREEN}Protocolo  | Puerto        | Servicio / Proceso${NC}"
echo -e "----------------------------------------------------"

# Extraemos y formateamos la información de netstat
netstat -tulnp 2>/dev/null | grep -E "^tcp|^udp" | while read proto recv send local_addr foreign_addr state pid_prog; do
    # Extraer el puerto de la dirección local (soportando IPv4 e IPv6)
    port=$(echo "$local_addr" | awk -F: '{print $NF}')
    
    # Extraer el nombre del programa (si es posible, si no mostrar "-")
    if [ "$pid_prog" != "-" ]; then
        prog=$(echo "$pid_prog" | awk -F/ '{print $NF}')
    else
        prog="Desconocido (requiere root)"
    fi
    
    printf "%-10s | %-13s | %s\n" "$proto" "$port" "$prog"
done | sort -k 3 -n -t '|' # Ordenar visualmente por puerto

echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
