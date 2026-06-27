#!/bin/bash
# ============================================================
# KRAKER VPS - Instalador Principal v2.0
# ============================================================
REPO_RAW="https://raw.githubusercontent.com/pedrorafaelcastillocalderon117-jpg/krakervps117/main"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║       KRAKER VPS - INSTALADOR v2.0          ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# Actualizar e instalar dependencias
echo -e "${YELLOW}[1/6] Instalando dependencias...${NC}"
apt-get update -y &>/dev/null
apt-get install -y curl wget net-tools htop nano unzip dos2unix iptables sudo bc python3 &>/dev/null
echo -e "${GREEN}      ✓ Listo${NC}"

# Crear directorios necesarios
echo -e "${YELLOW}[2/6] Preparando directorios...${NC}"
mkdir -p /etc/script_vps/{modulos,limites,banners,uids}
mkdir -p /etc/ssh/sshd_config.d
echo -e "${GREEN}      ✓ Listo${NC}"

# Descargar/actualizar todos los módulos desde GitHub
echo -e "${YELLOW}[3/6] Descargando módulos desde GitHub...${NC}"
wget -q "$REPO_RAW/menu.sh" -O /etc/script_vps/menu.sh
for mod in user_add user_del user_edit monitor_users install_dropbear_mod install_websocket; do
    wget -q "$REPO_RAW/modulos/${mod}.sh" -O "/etc/script_vps/modulos/${mod}.sh"
done
chmod +x /etc/script_vps/menu.sh
chmod +x /etc/script_vps/modulos/*.sh 2>/dev/null
ln -sf /etc/script_vps/menu.sh /usr/local/bin/menu
rm -f /etc/sudoers.d/krakervps
echo -e "${GREEN}      ✓ Listo${NC}"

# Crear/actualizar el Cronjob de banners dinámicos
echo -e "${YELLOW}[4/6] Configurando generador de banners dinámicos...${NC}"
cat << 'CRONEOF' > /usr/local/bin/kraker_consumo.sh
#!/bin/bash
# KRAKER - Generador de Banners Dinámicos con Tracking real via ss + auth.log

mkdir -p /etc/script_vps/{banners,consumo_last,consumo_total,limites}

# PASO 1: Mapear PID de Dropbear → Usuario usando auth.log
declare -A PID_USER
for logfile in /var/log/auth.log /var/log/syslog; do
    [ -f "$logfile" ] || continue
    while IFS= read -r line; do
        pid=$(echo "$line" | grep -oP 'dropbear\[\K[0-9]+')
        user=$(echo "$line" | grep -oP "(?:Password|Pubkey) auth succeeded for '?\K[a-zA-Z0-9_.-]+")
        [ -n "$pid" ] && [ -n "$user" ] && PID_USER[$pid]="$user"
    done < <(grep -E "dropbear.*auth succeeded" "$logfile" 2>/dev/null | tail -500)
done

# PASO 2: Obtener bytes reales por PID de Dropbear en puerto 80 usando ss
declare -A PID_BYTES
current_pid=""
while IFS= read -r line; do
    if echo "$line" | grep -qP '"dropbear",pid=\d+'; then
        current_pid=$(echo "$line" | grep -oP '"dropbear",pid=\K[0-9]+')
    elif [ -n "$current_pid" ] && echo "$line" | grep -q 'bytes_sent:'; then
        sent=$(echo "$line" | grep -oP 'bytes_sent:\K[0-9]+' || echo 0)
        recv=$(echo "$line" | grep -oP 'bytes_received:\K[0-9]+' || echo 0)
        [ -z "$sent" ] && sent=0
        [ -z "$recv" ] && recv=0
        PID_BYTES[$current_pid]=$(( sent + recv ))
        current_pid=""
    fi
done < <(ss -tipn 2>/dev/null)

# PASO 3: Sumar bytes por usuario y acumular (para no perder datos al desconectarse)
declare -A USER_CURRENT
for pid in "${!PID_BYTES[@]}"; do
    user="${PID_USER[$pid]}"
    [ -z "$user" ] && continue
    USER_CURRENT[$user]=$(( ${USER_CURRENT[$user]:-0} + ${PID_BYTES[$pid]} ))
done

for user in "${!USER_CURRENT[@]}"; do
    current="${USER_CURRENT[$user]}"
    last=$(cat "/etc/script_vps/consumo_last/$user" 2>/dev/null || echo 0)
    total=$(cat "/etc/script_vps/consumo_total/$user" 2>/dev/null || echo 0)
    [ -z "$last" ] && last=0
    [ -z "$total" ] && total=0
    if [ "$current" -gt "$last" ]; then
        delta=$(( current - last ))
        total=$(( total + delta ))
        echo "$total" > "/etc/script_vps/consumo_total/$user"
    fi
    echo "$current" > "/etc/script_vps/consumo_last/$user"
done

# PASO 4: Generar banner HTML premium para cada usuario
for limite_file in /etc/script_vps/limites/*; do
    [ -e "$limite_file" ] || continue
    username=$(basename "$limite_file")
    id "$username" &>/dev/null || continue

    # Calcular días restantes
    EXP_DATE=$(chage -l "$username" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
    if [ "$EXP_DATE" = "never" ] || [ -z "$EXP_DATE" ]; then
        EXP_TXT="Ilimitado"; DIAS_RESTANTES="&infin;"
    else
        EXP_SEC=$(date -d "$EXP_DATE" +%s 2>/dev/null); NOW_SEC=$(date +%s)
        if [ -n "$EXP_SEC" ]; then
            DIFF=$(( EXP_SEC - NOW_SEC ))
            if [ $DIFF -lt 0 ]; then DIAS_RESTANTES="EXPIRADO"; EXP_TXT="$EXP_DATE"
            else DIAS_RESTANTES=$(( DIFF / 86400 )); EXP_TXT="$EXP_DATE"; fi
        else EXP_TXT="?"; DIAS_RESTANTES="-"; fi
    fi

    # Leer consumo acumulado
    BYTES=$(cat "/etc/script_vps/consumo_total/$username" 2>/dev/null || echo 0)
    [ -z "$BYTES" ] && BYTES=0

    # Formatear
    if [ "$BYTES" -lt 1024 ]; then
        CONSUMO="${BYTES} B"
    elif [ "$BYTES" -lt 1048576 ]; then
        CONSUMO="$(awk "BEGIN{printf \"%.2f\", $BYTES/1024}") KB"
    elif [ "$BYTES" -lt 1073741824 ]; then
        CONSUMO="$(awk "BEGIN{printf \"%.2f\", $BYTES/1048576}") MB"
    else
        CONSUMO="$(awk "BEGIN{printf \"%.2f\", $BYTES/1073741824}") GB"
    fi

    LIMITE="1"
    [ -f "/etc/script_vps/limites/$username" ] && LIMITE=$(cat "/etc/script_vps/limites/$username")

    cat << BANN > "/etc/script_vps/banners/$username"
<br><br>
<font color='#00FFFF'>╔════════════════════════════════════════════════╗</font><br>
<font color='#00FFFF'>║</font><font color='#FFD700'><b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;★&nbsp;&nbsp;K R A K E R&nbsp;&nbsp;V P N&nbsp;&nbsp;★&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</b></font><font color='#00FFFF'>║</font><br>
<font color='#00FFFF'>║&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Conexi&oacute;n Segura Establecida&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</font><font color='#00FFFF'>║</font><br>
<font color='#00FFFF'>╠════════════════════════════════════════════════╣</font><br>
<font color='#00FFFF'>║</font>&nbsp;<font color='#888888'>👤&nbsp;Usuario&nbsp;&nbsp;:</font>&nbsp;<font color='#00FF00'><b>&nbsp;$username</b></font><br>
<font color='#00FFFF'>║</font>&nbsp;<font color='#888888'>📅&nbsp;Vence&nbsp;&nbsp;&nbsp;&nbsp;:</font>&nbsp;<font color='#FFFF00'>&nbsp;$EXP_TXT</font><br>
<font color='#00FFFF'>║</font>&nbsp;<font color='#888888'>⏳&nbsp;Quedan&nbsp;&nbsp;&nbsp;:</font>&nbsp;<font color='#FF6600'><b>&nbsp;$DIAS_RESTANTES d&iacute;as</b></font><br>
<font color='#00FFFF'>║</font>&nbsp;<font color='#888888'>📊&nbsp;Consumo&nbsp;&nbsp;:</font>&nbsp;<font color='#00FFFF'><b>&nbsp;$CONSUMO</b></font><br>
<font color='#00FFFF'>║</font>&nbsp;<font color='#888888'>🔗&nbsp;M&aacute;x IPs&nbsp;:</font>&nbsp;<font color='#FF69B4'>&nbsp;$LIMITE conexiones</font><br>
<font color='#00FFFF'>╚════════════════════════════════════════════════╝</font><br>
<font color='#444444'>&nbsp;&nbsp;🔒&nbsp;Powered by KRAKER VPN</font><br>
<br>
BANN
done
CRONEOF

chmod +x /usr/local/bin/kraker_consumo.sh
# Crontab cada minuto
if ! crontab -l 2>/dev/null | grep -q "kraker_consumo.sh"; then
    (crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/kraker_consumo.sh") | crontab -
fi
/usr/local/bin/kraker_consumo.sh
echo -e "${GREEN}      ✓ Listo${NC}"

# Configurar OpenSSH (banner estático de respaldo + solo puerto 22)
echo -e "${YELLOW}[5/6] Configurando OpenSSH...${NC}"
cat << 'EOF' > /etc/issue.net
<br><br>
<font color='#00FFFF'>╔════════════════════════════════════════════════╗</font><br>
<font color='#00FFFF'>║</font><font color='#FFD700'><b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;★&nbsp;&nbsp;K R A K E R&nbsp;&nbsp;V P N&nbsp;&nbsp;★&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</b></font><font color='#00FFFF'>║</font><br>
<font color='#00FFFF'>║&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Conexi&oacute;n Segura Establecida&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</font><font color='#00FFFF'>║</font><br>
<font color='#00FFFF'>╚════════════════════════════════════════════════╝</font><br>
<br>
EOF
# Quitar Port 80 de OpenSSH (Dropbear debe usarlo)
sed -i '/^Port 80$/d' /etc/ssh/sshd_config
sed -i 's/^#Banner.*/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config
if ! grep -q "^Banner" /etc/ssh/sshd_config; then
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
fi
systemctl restart sshd 2>/dev/null
echo -e "${GREEN}      ✓ Listo${NC}"

# Instalar Dropbear Modificado (solo si no está ya instalado)
echo -e "${YELLOW}[6/6] Verificando Dropbear KRAKER Mod...${NC}"
MARKER="/etc/script_vps/.dropbear_kraker_ok"
if [ ! -f "$MARKER" ]; then
    echo -e "      Compilando Dropbear Mod (1-3 min)..."
    chmod +x /etc/script_vps/modulos/install_dropbear_mod.sh
    /etc/script_vps/modulos/install_dropbear_mod.sh
    if systemctl is-active --quiet dropbear; then
        touch "$MARKER"
    fi
else
    echo -e "      Dropbear Mod ya instalado. Reiniciando..."
    systemctl restart dropbear 2>/dev/null
fi
echo -e "${GREEN}      ✓ Listo${NC}"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    ✅  INSTALACIÓN COMPLETADA EXITOSAMENTE   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo -e "Escribe ${YELLOW}menu${NC} para iniciar el panel."
