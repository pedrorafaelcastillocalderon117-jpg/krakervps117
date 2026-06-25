#!/bin/bash
# Menú Principal del Script VPS

# Colores
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Función de limpiar pantalla y banner
show_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${GREEN} __     __  ____    ____      _  __  ____      _      _  __  _____  ____  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN} \ \   / / |  _ \  / ___|    | |/ / |  _ \    / \    | |/ / | ____||  _ \ ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}  \ \ / /  | |_) | \___ \    | ' /  | |_) |  / _ \   | ' /  |  _|  | |_) |${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}   \ V /   |  __/   ___) |   | . \  |  _ <  / ___ \  | . \  | |___ |  _ < ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}    \_/    |_|     |____/    |_|\_\ |_| \_\/_/   \_\ |_|\_\ |_____||_| \_\ ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${YELLOW}Sistema :${NC} $(lsb_release -d | awk -F'\t' '{print $2}')"
    echo -e "${CYAN}║${NC} ${YELLOW}IP Local:${NC} $(curl -s -4 ifconfig.me)"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}GESTIÓN DE USUARIOS${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}[1]${NC} Crear Usuario SSH/Dropbear       ${GREEN}[2]${NC} Eliminar Usuario"
    echo -e "${CYAN}║${NC} ${GREEN}[8]${NC} Monitor de Usuarios Conectados"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}INSTALACIÓN DE PROTOCOLOS Y TÚNELES${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}[3]${NC} Instalar Dropbear                ${GREEN}[4]${NC} Instalar Stunnel4 (SSL)"
    echo -e "${CYAN}║${NC} ${GREEN}[5]${NC} Instalar Squid Proxy             ${GREEN}[6]${NC} Instalar V2Ray (VMess)"
    echo -e "${CYAN}║${NC} ${GREEN}[7]${NC} Instalar OpenVPN                 ${GREEN}[9]${NC} Instalar BadVPN (UDPGW)"
    echo -e "${CYAN}║${NC} ${GREEN}[13]${NC} Instalar Proxy WS (Multiplexor)"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}HERRAMIENTAS Y OPTIMIZACIÓN${NC}"
    echo -e "${CYAN}║${NC} ${GREEN}[10]${NC} Optimizar y Limpiar RAM         ${GREEN}[11]${NC} Instalar BBR Plus"
    echo -e "${CYAN}║${NC} ${GREEN}[12]${NC} Monitor de Puertos Abiertos"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} ${RED}[0] Salir del Administrador${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e ""
    read -p " ❯ Selecciona una opción: " opcion

    case $opcion in
        1)
            /etc/script_vps/modulos/user_add.sh
            ;;
        2)
            /etc/script_vps/modulos/user_del.sh
            ;;
        3)
            /etc/script_vps/modulos/install_dropbear.sh
            ;;
        4)
            /etc/script_vps/modulos/install_stunnel.sh
            ;;
        5)
            /etc/script_vps/modulos/install_squid.sh
            ;;
        6)
            /etc/script_vps/modulos/install_v2ray.sh
            ;;
        7)
            /etc/script_vps/modulos/install_openvpn.sh
            ;;
        8)
            /etc/script_vps/modulos/monitor_users.sh
            ;;
        9)
            /etc/script_vps/modulos/install_badvpn.sh
            ;;
        10)
            /etc/script_vps/modulos/optimizar.sh
            ;;
        11)
            /etc/script_vps/modulos/install_bbr.sh
            ;;
        12)
            /etc/script_vps/modulos/monitor_puertos.sh
            ;;
        13)
            /etc/script_vps/modulos/install_websocket.sh
            ;;
        0)
            clear
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida. Intenta nuevamente.${NC}"
            sleep 2
            ;;
    esac
    show_menu
}

# Bucle del menú
show_menu
