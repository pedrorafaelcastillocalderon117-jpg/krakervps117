#!/bin/bash
# Instalador de V2Ray (VMess + WebSocket)

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}               INSTALADOR DE V2RAY                  ${NC}"
echo -e "${CYAN}====================================================${NC}"

# Validar dominio forzosamente
read -p "Ingresa tu dominio para V2Ray (obligatorio): " v2ray_domain
if [ -z "$v2ray_domain" ]; then
    echo -e "${RED}El dominio es obligatorio para V2Ray. Cancelando instalación...${NC}"
    sleep 2
    exit 1
fi

echo -e "${GREEN}Instalando V2Ray (Xray-core compatible)...${NC}"
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) &>/dev/null

UUID=$(cat /proc/sys/kernel/random/uuid)
PORT=80

# Configuración de V2Ray (VMess + WS)
cat <<EOF > /usr/local/etc/v2ray/config.json
{
  "inbounds": [
    {
      "port": $PORT,
      "listen": "0.0.0.0",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/v2ray"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

systemctl restart v2ray
systemctl enable v2ray &>/dev/null

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN}V2Ray instalado correctamente.${NC}"
echo -e "Dominio: ${YELLOW}$v2ray_domain${NC}"
echo -e "Puerto: ${YELLOW}$PORT${NC}"
echo -e "UUID: ${YELLOW}$UUID${NC}"
echo -e "Ruta (Path): ${YELLOW}/v2ray${NC}"
echo -e "Protocolo: ${YELLOW}VMess + WebSocket${NC}"
echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
