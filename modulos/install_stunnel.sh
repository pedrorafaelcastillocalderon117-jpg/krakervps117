#!/bin/bash
# Instalador de Stunnel4

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}               INSTALADOR DE STUNNEL4               ${NC}"
echo -e "${CYAN}====================================================${NC}"

echo -e "${GREEN}Instalando Stunnel4 y openssl...${NC}"
apt-get install stunnel4 openssl -y &>/dev/null

# Configuración para habilitar Stunnel
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4

IP=$(curl -s ifconfig.me)
if [ -z "$IP" ]; then IP="127.0.0.1"; fi

echo -e "${YELLOW}¿Tienes un dominio apuntando a esta VPS para los certificados SSL? (s/n)${NC}"
read -p " Opción: " has_domain

mkdir -p /etc/stunnel

if [[ "$has_domain" == "s" || "$has_domain" == "S" ]]; then
    read -p " Ingresa tu dominio (ej. midominio.com): " cert_domain
    cert_domain=$(echo "$cert_domain" | xargs)
    echo -e "${GREEN}Generando certificado SSL para el dominio: $cert_domain...${NC}"
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$cert_domain" \
        -keyout /etc/stunnel/stunnel.pem  -out /etc/stunnel/stunnel.pem
else
    echo -e "${GREEN}Generando certificado SSL para la IP: $IP...${NC}"
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$IP" \
        -keyout /etc/stunnel/stunnel.pem  -out /etc/stunnel/stunnel.pem
fi

# Corregir permisos obligatorios para Stunnel
chmod 600 /etc/stunnel/stunnel.pem

echo -e "${YELLOW}Configuración de puertos para Stunnel${NC}"
read -p " Puerto de escucha SSL público (ej. 443): " ssl_port
if [ -z "$ssl_port" ]; then ssl_port=443; fi

read -p " Puerto interno destino (ej. puerto Dropbear 80): " dest_port
if [ -z "$dest_port" ]; then dest_port=80; fi

# Detener Apache/Nginx por si están bloqueando el puerto 443
systemctl stop apache2 nginx &>/dev/null
systemctl disable apache2 nginx &>/dev/null

# Crear configuración
cat <<EOF > /etc/stunnel/stunnel.conf
cert = /etc/stunnel/stunnel.pem
client = no
sslVersion = all
options = NO_SSLv2
options = NO_SSLv3
ciphers = ECDHE-RSA-AES128-GCM-SHA256:AES128-SHA
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[tunnel]
accept = $ssl_port
connect = 127.0.0.1:$dest_port
EOF

# Reiniciar servicio
systemctl restart stunnel4
systemctl enable stunnel4 &>/dev/null

echo -e "${GREEN}Stunnel4 ha sido configurado en el puerto $ssl_port apuntando al puerto $dest_port internamente.${NC}"
echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
