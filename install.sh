#!/bin/bash
# Instalador principal del Script VPS

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Iniciando la instalación de dependencias base para el Script VPS...${NC}"

# Actualizar repositorios
echo -e "${YELLOW}Actualizando paquetes del sistema...${NC}"
apt-get update -y
apt-get upgrade -y

# Instalar utilidades esenciales
echo -e "${YELLOW}Instalando utilidades (curl, wget, net-tools, htop)...${NC}"
apt-get install -y curl wget net-tools htop nano unzip dos2unix

# Crear directorios del script
mkdir -p /etc/script_vps
mkdir -p /etc/script_vps/modulos

# Preparar entorno del menú
cp menu.sh /etc/script_vps/menu.sh
cp -r modulos/* /etc/script_vps/modulos/ 2>/dev/null

chmod +x /etc/script_vps/menu.sh
chmod +x /etc/script_vps/modulos/* 2>/dev/null

# Crear comando de acceso rápido al menú
ln -sf /etc/script_vps/menu.sh /usr/local/bin/menu

echo -e "${GREEN}Instalación completada.${NC}"
echo -e "Escribe ${YELLOW}menu${NC} en la terminal para iniciar."
