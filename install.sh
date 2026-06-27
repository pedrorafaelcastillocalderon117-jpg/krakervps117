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
apt-get install -y curl wget net-tools htop nano unzip dos2unix iptables

# Crear directorios del script
mkdir -p /etc/script_vps
mkdir -p /etc/script_vps/modulos
mkdir -p /etc/script_vps/limites

# Preparar entorno del menú
cp menu.sh /etc/script_vps/menu.sh
cp -r modulos/* /etc/script_vps/modulos/ 2>/dev/null

chmod +x /etc/script_vps/menu.sh
chmod +x /etc/script_vps/modulos/* 2>/dev/null

# Crear comando de acceso rápido al menú
ln -sf /etc/script_vps/menu.sh /usr/local/bin/menu

# Crear banner de respaldo estático (issue.net) para apps que no leen vpnshell
cat << 'EOF' > /etc/issue.net
<br>
<font color='#00FFFF'>========================================</font><br>
<font color='#00FF00'><b>&nbsp;&nbsp;K R A K E R &nbsp;&nbsp;V P N</b></font><br>
<font color='#FFFFFF'>--- Conexión Establecida ---</font><br>
<font color='#00FFFF'>========================================</font><br>
EOF
sed -i 's/^#Banner.*/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config
sed -i 's/^Banner.*/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config
systemctl restart sshd 2>/dev/null

echo -e "${GREEN}Instalación completada.${NC}"
echo -e "Escribe ${YELLOW}menu${NC} en la terminal para iniciar."
