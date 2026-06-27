#!/bin/bash
# install_dropbear_mod.sh - Compila Dropbear Modificado (KRAKER)

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}  FABRICANDO DROPBEAR KRAKER MOD (Banners Dinámicos)${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Por favor, espera de 1 a 3 minutos mientras se compila el motor SSH..."

# Detener cualquier dropbear viejo
systemctl stop dropbear 2>/dev/null
pkill dropbear

# Instalar dependencias necesarias para compilar en C
apt-get update -y &>/dev/null
apt-get install -y build-essential zlib1g-dev libcrypt-dev gcc make wget &>/dev/null

# Limpiar directorio temporal
rm -rf /tmp/dropbear_build
mkdir -p /tmp/dropbear_build
cd /tmp/dropbear_build

# Descargar código fuente oficial
wget -q https://matt.ucc.asn.au/dropbear/releases/dropbear-2022.83.tar.bz2
tar -xjf dropbear-2022.83.tar.bz2
cd dropbear-2022.83

# PARCHE MAGICO: Inyectar código C en svr-auth.c para interceptar el banner
sed -i '/send_msg_userauth_banner(svr_opts.banner);/c\
\tchar bpath[256];\n\tsnprintf(bpath, sizeof(bpath), "/etc/script_vps/banners/%s", ses.authstate.username);\n\tint fd = open(bpath, O_RDONLY);\n\tif (fd >= 0) {\n\t\tbuffer *cb = buf_new(2048);\n\t\tint len = read(fd, cb->data, 2048);\n\t\tif (len > 0) {\n\t\t\tcb->len = len;\n\t\t\tsend_msg_userauth_banner(cb);\n\t\t}\n\t\tbuf_free(cb);\n\t\tclose(fd);\n\t} else if (svr_opts.banner != NULL) {\n\t\tsend_msg_userauth_banner(svr_opts.banner);\n\t}' svr-auth.c

# Compilar
./configure --disable-zlib &>/dev/null
make PROGRAMS="dropbear" &>/dev/null

# Instalar y reemplazar el binario oficial
cp dropbear /usr/sbin/dropbear
chmod +x /usr/sbin/dropbear

# Limpiar basura
rm -rf /tmp/dropbear_build

# Configurar Dropbear (Puerto 80)
drop_port=80
extra_args="-p 80 -p 143"
cat <<EOF > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=$drop_port
DROPBEAR_EXTRA_ARGS="$extra_args"
DROPBEAR_BANNER="/etc/issue.net"
EOF

# Reiniciar Servicio
systemctl enable dropbear 2>/dev/null
systemctl restart dropbear

echo -e "${GREEN}¡Dropbear Kraker Mod compilado e instalado con éxito!${NC}"
echo -e "${CYAN}====================================================${NC}"
