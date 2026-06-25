#!/bin/bash
# Instalador de Squid Proxy

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}                INSTALADOR DE SQUID                 ${NC}"
echo -e "${CYAN}====================================================${NC}"

echo -e "${GREEN}Instalando Squid3...${NC}"
apt-get install squid3 -y &>/dev/null || apt-get install squid -y &>/dev/null

IP=$(curl -s ifconfig.me)

# Configuración básica de Squid
cat <<EOF > /etc/squid/squid.conf
http_port 80
http_port 8080
http_port 3128
http_port 8799

acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl localnet src fc00::/7
acl localnet src fe80::/10

acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT

http_access allow manager localhost
http_access deny manager

# Permitir payload y conexion
http_access allow all

# Regla de payload SSH
acl ssh_payload url_regex -i ^[a-zA-Z0-9.-]+\.com$
http_access allow ssh_payload

coredump_dir /var/spool/squid
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern .               0       20%     4320
EOF

# Reiniciar servicio
systemctl restart squid
systemctl enable squid &>/dev/null

echo -e "${GREEN}Squid Proxy configurado en los puertos 80, 8080, 3128 y 8799.${NC}"
echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
