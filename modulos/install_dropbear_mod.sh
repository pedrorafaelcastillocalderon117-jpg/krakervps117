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

# Aplicar parche con Python (regex robusto)
echo -e "${CYAN}[3/5]${NC} Aplicando parche de banners dinámicos..."
python3 - << 'PYEOF'
import re, sys

with open('svr-auth.c', 'r') as f:
    src = f.read()

# Añadir include para open() si no está
if '#include <fcntl.h>' not in src:
    src = '#include <fcntl.h>\n' + src

# Patrón flexible: busca el if (svr_opts.banner) { send_msg... } completo
pattern = re.compile(
    r'if\s*\(\s*svr_opts\.banner\s*\)\s*\{[^}]*send_msg_userauth_banner\s*\([^)]+\)\s*;\s*\}',
    re.DOTALL
)

replacement = r'''/* KRAKER MOD: Banner dinamico por usuario */
	{
		const char *_uname = ses.authstate.username;
		int _bfd = -1;
		if (_uname && _uname[0] != '\0') {
			char _bpath[256];
			snprintf(_bpath, sizeof(_bpath), "/etc/script_vps/banners/%s", _uname);
			_bfd = open(_bpath, O_RDONLY);
		}
		if (_bfd >= 0) {
			buffer *_ub = buf_new(4096);
			unsigned char *_wp = buf_getwriteptr(_ub, 4096);
			ssize_t _blen = read(_bfd, _wp, 4096);
			close(_bfd);
			if (_blen > 0) {
				buf_incrwritepos(_ub, (unsigned int)_blen);
				send_msg_userauth_banner(_ub);
			}
			buf_free(_ub);
		} else if (svr_opts.banner) {
			send_msg_userauth_banner(svr_opts.banner);
		}
	}
	/* FIN KRAKER MOD */'''

match = pattern.search(src)
if match:
    src = src[:match.start()] + replacement + src[match.end():]
    with open('svr-auth.c', 'w') as f:
        f.write(src)
    print('PATCH_OK: Parche aplicado en posicion', match.start())
else:
    # Fallback: buscar solo la llamada directa
    simple_pat = re.compile(r'send_msg_userauth_banner\s*\(\s*svr_opts\.banner\s*\)\s*;')
    m2 = simple_pat.search(src)
    if m2:
        src = src[:m2.start()] + replacement.strip().split('{',1)[1].rsplit('}',1)[0] + src[m2.end():]
        with open('svr-auth.c', 'w') as f:
            f.write(src)
        print('PATCH_OK_FALLBACK: Parche aplicado (fallback)')
    else:
        print('PATCH_FAIL: Patron no encontrado en esta version de Dropbear')
        sys.exit(1)
PYEOF

if [ $? -ne 0 ]; then
    echo -e "      ${RED}✗ Parche fallido${NC}"; exit 1
fi
echo -e "      ${GREEN}✓ Parche aplicado correctamente${NC}"

# Compilar
echo -e "${CYAN}[4/5]${NC} Compilando (puede tardar 1-3 minutos)..."
./configure LDFLAGS="-lcrypt" &>/dev/null
make PROGRAMS="dropbear" 2>&1 | tail -5
if [ $? -ne 0 ]; then
    echo -e "      ${YELLOW}⚠ Reintentando compilación...${NC}"
    make clean &>/dev/null
    ./configure &>/dev/null
    make PROGRAMS="dropbear" &>/tmp/make2.log
    if [ $? -ne 0 ]; then
        echo -e "      ${RED}✗ Error de compilación. Usando Dropbear estándar.${NC}"
        apt-get install -y dropbear &>/dev/null
        FALLBACK=1
    fi
fi
echo -e "      ${GREEN}✓ Compilado${NC}"

# Instalar binario
echo -e "${CYAN}[5/5]${NC} Instalando Dropbear..."
[ -z "$FALLBACK" ] && cp dropbear /usr/sbin/dropbear && chmod +x /usr/sbin/dropbear

# Generar claves host si no existen
mkdir -p /etc/dropbear
[ ! -f /etc/dropbear/dropbear_rsa_host_key ] && \
    dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key &>/dev/null
[ ! -f /etc/dropbear/dropbear_ecdsa_host_key ] && \
    dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key &>/dev/null

# Configurar Dropbear
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
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅  Dropbear KRAKER Mod activo en 80/143   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}⚠ Dropbear no está activo. Revisa: systemctl status dropbear${NC}"
fi
