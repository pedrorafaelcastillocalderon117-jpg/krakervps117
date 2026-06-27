#!/bin/bash
# ============================================================
# KRAKER VPS - Compilador de Dropbear Mod (Banners por usuario)
# ============================================================
GREEN='\033[1;32m'; YELLOW='\033[1;33m'; CYAN='\033[1;36m'
RED='\033[1;31m'; NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║   🔧  DROPBEAR KRAKER MOD - COMPILANDO   🔧  ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# Detener Dropbear anterior
systemctl stop dropbear 2>/dev/null
pkill -9 dropbear 2>/dev/null
sleep 1

# Dependencias
echo -e "${CYAN}[1/5]${NC} Instalando dependencias de compilación..."
apt-get update -y &>/dev/null
apt-get install -y build-essential zlib1g-dev libcrypt-dev gcc make wget python3 &>/dev/null
echo -e "      ${GREEN}✓ OK${NC}"

# Descargar fuente
echo -e "${CYAN}[2/5]${NC} Descargando Dropbear 2022.83..."
rm -rf /tmp/dropbear_build && mkdir -p /tmp/dropbear_build
cd /tmp/dropbear_build
wget -q https://matt.ucc.asn.au/dropbear/releases/dropbear-2022.83.tar.bz2 -O dropbear.tar.bz2
if [ $? -ne 0 ]; then
    echo -e "      ${RED}✗ Error de descarga${NC}"; exit 1
fi
tar -xjf dropbear.tar.bz2
cd dropbear-2022.83
echo -e "      ${GREEN}✓ OK${NC}"

# Aplicar parche con Python - CORRECTO para Dropbear 2022.83
echo -e "${CYAN}[3/5]${NC} Aplicando parche de banners dinámicos..."
python3 << 'PYEOF'
import sys

with open('svr-auth.c', 'r') as f:
    src = f.read()

# Añadir include para open()/read() si no está
if '#include <fcntl.h>' not in src:
    src = '#include <fcntl.h>\n' + src

# BLOQUE ORIGINAL EXACTO en Dropbear 2022.83 (confirmado en el código fuente):
# El banner se envía ANTES de leer el username, así que hacemos peek del payload
OLD = '''\t/* send the banner if it exists, it will only exist once */
\tif (svr_opts.banner) {
\t\tsend_msg_userauth_banner(svr_opts.banner);
\t\tbuf_free(svr_opts.banner);
\t\tsvr_opts.banner = NULL;
\t}'''

NEW = '''\t/* KRAKER MOD: Banner dinamico por usuario */
\t{
\t\t/* Leer username del payload sin consumirlo (peek) */
\t\tunsigned int _saved_pos = ses.payload->pos;
\t\tunsigned int _ulen = 0;
\t\tchar *_uname = buf_getstring(ses.payload, &_ulen);
\t\tbuf_setpos(ses.payload, _saved_pos); /* restaurar posicion */
\t\t
\t\tint _bfd = -1;
\t\tif (_uname && _uname[0]) {
\t\t\tchar _bpath[256];
\t\t\tsnprintf(_bpath, sizeof(_bpath), "/etc/script_vps/banners/%s", _uname);
\t\t\t_bfd = open(_bpath, O_RDONLY);
\t\t}
\t\tm_free(_uname);
\t\t
\t\tif (_bfd >= 0) {
\t\t\tbuffer *_ub = buf_new(4096);
\t\t\tunsigned char *_wp = buf_getwriteptr(_ub, 4096);
\t\t\tssize_t _blen = read(_bfd, _wp, 4096);
\t\t\tclose(_bfd);
\t\t\tif (_blen > 0) {
\t\t\t\tbuf_incrwritepos(_ub, (unsigned int)_blen);
\t\t\t\tsend_msg_userauth_banner(_ub);
\t\t\t} else if (svr_opts.banner) {
\t\t\t\tsend_msg_userauth_banner(svr_opts.banner);
\t\t\t}
\t\t\tbuf_free(_ub);
\t\t} else if (svr_opts.banner) {
\t\t\tsend_msg_userauth_banner(svr_opts.banner);
\t\t}
\t\t/* Liberar banner global (solo se manda una vez) */
\t\tif (svr_opts.banner) {
\t\t\tbuf_free(svr_opts.banner);
\t\t\tsvr_opts.banner = NULL;
\t\t}
\t}
\t/* FIN KRAKER MOD */'''

if OLD in src:
    src = src.replace(OLD, NEW, 1)
    with open('svr-auth.c', 'w') as f:
        f.write(src)
    print('PATCH_OK: Parche aplicado correctamente en Dropbear 2022.83')
else:
    print('ERROR: Patron exacto no encontrado. Verificando similitudes...')
    # Buscar variación con espacios
    import re
    pat = re.compile(r'/\* send the banner.*?svr_opts\.banner = NULL;\s*\}', re.DOTALL)
    m = pat.search(src)
    if m:
        print('ALTERNATIVO encontrado en posicion', m.start(), ':', repr(m.group()[:80]))
    else:
        print('Mostrando lineas 88-97 del archivo:')
        lines = src.split('\n')
        for i, l in enumerate(lines[87:97], 88):
            print(f'{i}: {repr(l)}')
    sys.exit(1)
PYEOF

PATCH_STATUS=$?
if [ $PATCH_STATUS -ne 0 ]; then
    echo -e "      ${RED}✗ Parche fallido. Abortando.${NC}"
    exit 1
fi
echo -e "      ${GREEN}✓ Parche aplicado correctamente${NC}"

# Compilar
echo -e "${CYAN}[4/5]${NC} Compilando (puede tardar 1-3 minutos)..."
./configure LDFLAGS="-lcrypt" &>/dev/null
make PROGRAMS="dropbear" 2>&1 | grep -E "error:|warning:|Linking" | tail -10
if [ $? -ne 0 ]; then
    echo -e "      ${YELLOW}⚠ Reintentando compilación sin flags extra...${NC}"
    make clean &>/dev/null
    ./configure &>/dev/null
    make PROGRAMS="dropbear" 2>&1 | grep -E "error:|Linking" | tail -5
    if [ $? -ne 0 ]; then
        echo -e "      ${RED}✗ Compilación fallida.${NC}"; exit 1
    fi
fi
echo -e "      ${GREEN}✓ Compilado exitosamente${NC}"

# Instalar binario
echo -e "${CYAN}[5/5]${NC} Instalando Dropbear KRAKER..."
cp dropbear /usr/sbin/dropbear
chmod +x /usr/sbin/dropbear

# Generar claves host si no existen
mkdir -p /etc/dropbear
[ ! -f /etc/dropbear/dropbear_rsa_host_key ] && \
    dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key &>/dev/null
[ ! -f /etc/dropbear/dropbear_ecdsa_host_key ] && \
    dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key &>/dev/null

# Configurar Dropbear (puerto 80 y 143)
cat << 'EOF' > /etc/default/dropbear
NO_START=0
DROPBEAR_PORT=80
DROPBEAR_EXTRA_ARGS="-p 80 -p 143"
DROPBEAR_BANNER="/etc/issue.net"
EOF

# Quitar Port 80 de OpenSSH para evitar conflicto
sed -i '/^Port 80$/d' /etc/ssh/sshd_config
systemctl restart sshd 2>/dev/null

# Limpiar temporales
rm -rf /tmp/dropbear_build

# Iniciar Dropbear
systemctl enable dropbear 2>/dev/null
systemctl restart dropbear
sleep 2

if systemctl is-active --quiet dropbear; then
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║  ✅  Dropbear KRAKER Mod activo en 80/143   ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
else
    echo -e "${RED}⚠ Dropbear no está activo. Revisa: systemctl status dropbear${NC}"
fi
