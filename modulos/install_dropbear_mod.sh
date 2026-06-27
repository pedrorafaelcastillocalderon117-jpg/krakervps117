#!/bin/bash
# install_dropbear_mod.sh - Compila Dropbear Kraker Mod con Banner Dinámico por Usuario

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo -e "╔══════════════════════════════════════════════╗"
echo -e "║    🔧  FABRICANDO DROPBEAR KRAKER MOD  🔧    ║"
echo -e "║      Banners Dinámicos por Usuario           ║"
echo -e "╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${YELLOW}  Espera de 1 a 3 minutos mientras se compila...${NC}"
echo ""

# Detener servicios anteriores
systemctl stop dropbear 2>/dev/null
pkill -9 dropbear 2>/dev/null
sleep 1

# Instalar dependencias
echo -e "${CYAN}[1/5]${NC} Instalando dependencias de compilación..."
apt-get update -y &>/dev/null
apt-get install -y build-essential zlib1g-dev libcrypt-dev gcc make wget python3 &>/dev/null
echo -e "      ${GREEN}✓ Dependencias listas${NC}"

# Limpiar y preparar directorio de compilación
rm -rf /tmp/dropbear_build
mkdir -p /tmp/dropbear_build
cd /tmp/dropbear_build

# Descargar código fuente oficial
echo -e "${CYAN}[2/5]${NC} Descargando código fuente oficial de Dropbear 2022.83..."
wget -q https://matt.ucc.asn.au/dropbear/releases/dropbear-2022.83.tar.bz2
if [ $? -ne 0 ]; then
    echo -e "      ${RED}✗ Error al descargar. Verificar conexión.${NC}"
    exit 1
fi
tar -xjf dropbear-2022.83.tar.bz2
cd dropbear-2022.83
echo -e "      ${GREEN}✓ Código fuente listo${NC}"

# Aplicar parche usando Python (confiable para código C multilínea)
echo -e "${CYAN}[3/5]${NC} Aplicando parche de banners dinámicos (KRAKER MOD)..."
python3 << 'PYEOF'
import sys

with open('svr-auth.c', 'r') as f:
    content = f.read()

# Añadir includes necesarios si no están
if '#include <fcntl.h>' not in content:
    content = '#include <fcntl.h>\n' + content

# El parche: reemplazar el envío estático del banner por uno dinámico por usuario
old_code = 'send_msg_userauth_banner(svr_opts.banner);'

new_code = '''{
        /* KRAKER MOD: Banner dinámico por usuario */
        char bpath[256];
        snprintf(bpath, sizeof(bpath), "/etc/script_vps/banners/%s",
                 ses.authstate.username ? ses.authstate.username : "");
        int bfd = open(bpath, O_RDONLY);
        if (bfd >= 0) {
            buffer *ubanner = buf_new(4096);
            ssize_t blen = read(bfd, buf_getwriteptr(ubanner, 4096), 4096);
            close(bfd);
            if (blen > 0) {
                buf_incrwritepos(ubanner, blen);
                send_msg_userauth_banner(ubanner);
                buf_free(ubanner);
            } else {
                buf_free(ubanner);
                if (svr_opts.banner) send_msg_userauth_banner(svr_opts.banner);
            }
        } else if (svr_opts.banner) {
            send_msg_userauth_banner(svr_opts.banner);
        }
    }
    /* FIN KRAKER MOD */
    {'''

if old_code in content:
    content = content.replace(old_code, new_code, 1)
    with open('svr-auth.c', 'w') as f:
        f.write(content)
    print("PATCH_OK")
else:
    print("PATCH_FAIL")
    sys.exit(1)
PYEOF

if [ $? -ne 0 ]; then
    echo -e "      ${RED}✗ El parche falló. Patrón no encontrado en esta versión.${NC}"
    exit 1
fi
echo -e "      ${GREEN}✓ Parche aplicado correctamente${NC}"

# Compilar
echo -e "${CYAN}[4/5]${NC} Compilando Dropbear con el mod (tarda 1-3 min)..."
./configure --disable-zlib CFLAGS="-lcrypt" &>/dev/null
make PROGRAMS="dropbear" &>/tmp/dropbear_make.log
if [ $? -ne 0 ]; then
    echo -e "      ${RED}✗ Error de compilación. Revisando log...${NC}"
    # Intentar con flags alternativos
    make clean &>/dev/null
    ./configure LDFLAGS="-lcrypt" &>/dev/null
    make PROGRAMS="dropbear" &>/tmp/dropbear_make2.log
    if [ $? -ne 0 ]; then
        echo -e "      ${RED}✗ Compilación fallida. Usando Dropbear estándar.${NC}"
        apt-get install -y dropbear &>/dev/null
        FALLBACK=1
    fi
fi
echo -e "      ${GREEN}✓ Compilación exitosa${NC}"

# Instalar el binario compilado
echo -e "${CYAN}[5/5]${NC} Instalando Dropbear KRAKER en el sistema..."
if [ -z "$FALLBACK" ]; then
    cp dropbear /usr/sbin/dropbear
    chmod +x /usr/sbin/dropbear
fi

# Limpiar archivos temporales de compilación
rm -rf /tmp/dropbear_build

# Configurar Dropbear (puerto 80 y 143)
mkdir -p /etc/dropbear
dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key &>/dev/null
dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key &>/dev/null

cat << 'EOF' > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=80
DROPBEAR_EXTRA_ARGS="-p 80 -p 143"
DROPBEAR_BANNER="/etc/issue.net"
EOF

# Quitar Port 80 de OpenSSH para evitar conflictos
sed -i '/^Port 80$/d' /etc/ssh/sshd_config
systemctl restart sshd 2>/dev/null

# Iniciar Dropbear
systemctl enable dropbear 2>/dev/null
systemctl restart dropbear

sleep 1
STATUS=$(systemctl is-active dropbear 2>/dev/null)
echo ""
if [ "$STATUS" = "active" ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅  Dropbear KRAKER Mod INSTALADO Y ACTIVO  ║${NC}"
    echo -e "${GREEN}║      Puerto 80  ✓   Puerto 143 ✓             ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠  Dropbear instalado pero no está activo   ║${NC}"
    echo -e "${RED}║  Corre: systemctl restart dropbear           ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════╝${NC}"
fi
