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
apt-get install -y curl wget net-tools htop nano unzip dos2unix iptables sudo

# Crear directorios del script
mkdir -p /etc/script_vps
mkdir -p /etc/script_vps/modulos
mkdir -p /etc/script_vps/limites
mkdir -p /etc/script_vps/banners
mkdir -p /etc/ssh/sshd_config.d

# Preparar entorno del menú
# Si tenemos la carpeta modulos local, la copiamos
if [ -d "modulos" ]; then
    cp menu.sh /etc/script_vps/menu.sh 2>/dev/null
    cp -r modulos/* /etc/script_vps/modulos/ 2>/dev/null
fi
# Si no, descargamos los módulos desde GitHub
if [ ! -f "/etc/script_vps/menu.sh" ]; then
    REPO_RAW="https://raw.githubusercontent.com/pedrorafaelcastillocalderon117-jpg/krakervps117/main"
    wget -q "$REPO_RAW/menu.sh" -O /etc/script_vps/menu.sh
    for mod in user_add user_del user_edit monitor_users install_dropbear_mod install_websocket; do
        wget -q "$REPO_RAW/modulos/${mod}.sh" -O "/etc/script_vps/modulos/${mod}.sh"
    done
fi

chmod +x /etc/script_vps/menu.sh
chmod +x /etc/script_vps/modulos/* 2>/dev/null

# Crear comando de acceso rápido al menú
ln -sf /etc/script_vps/menu.sh /usr/local/bin/menu

# Limpiar cualquier configuración vieja de sudoers que haya causado problemas
rm -f /etc/sudoers.d/krakervps

# Crear el script del Cronjob para banners dinámicos
cat << 'EOF' > /usr/local/bin/kraker_consumo.sh
#!/bin/bash
iptables-save -c > /etc/script_vps/consumos.txt
chmod 666 /etc/script_vps/consumos.txt

# Generar banners HTML individualizados
for limite_file in /etc/script_vps/limites/*; do
    [ -e "$limite_file" ] || continue
    username=$(basename "$limite_file")
    
    EXP_DATE=$(chage -l "$username" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
    if [ "$EXP_DATE" == "never" ] || [ -z "$EXP_DATE" ]; then
        EXP_TXT="Nunca"
        DIAS_RESTANTES="Ilimitados"
    else
        EXP_SEC=$(date -d "$EXP_DATE" +%s 2>/dev/null)
        NOW_SEC=$(date +%s)
        if [ -n "$EXP_SEC" ]; then
            DIFF=$(($EXP_SEC - $NOW_SEC))
            if [ $DIFF -lt 0 ]; then
                DIAS_RESTANTES="Expirado"
            else
                DIAS_RESTANTES=$(($DIFF / 86400))
            fi
            EXP_TXT=$EXP_DATE
        else
            EXP_TXT="Desconocida"
            DIAS_RESTANTES="-"
        fi
    fi

    UID_NUM=$(id -u "$username" 2>/dev/null)
    # Leer UID guardado si el id falla
    [ -z "$UID_NUM" ] && [ -f "/etc/script_vps/uids/$username" ] && UID_NUM=$(cat "/etc/script_vps/uids/$username")
    BYTES=0
    if [ -n "$UID_NUM" ] && [ "$UID_NUM" != "0" ]; then
        # iptables-save -c formato: [packets:bytes] -A CHAIN ... --uid-owner UID ...
        # Extraemos el campo bytes (segundo número entre [ y ])
        BYTES=$(grep -E "owner --uid-owner $UID_NUM( |$)" /etc/script_vps/consumos.txt | \
                grep -oP '^\[\d+:\K\d+(?=\])' | \
                awk '{s+=$1} END {print (s ? s : 0)}')
    fi
    [ -z "$BYTES" ] && BYTES=0

    if [ $BYTES -lt 1024 ]; then
        CONSUMO="${BYTES} B"
    elif [ $BYTES -lt 1048576 ]; then
        CONSUMO=$(echo "scale=2; $BYTES/1024" | bc 2>/dev/null || echo "$(($BYTES/1024)) KB")" KB"
    elif [ $BYTES -lt 1073741824 ]; then
        CONSUMO=$(echo "scale=2; $BYTES/1048576" | bc 2>/dev/null || echo "$(($BYTES/1048576)) MB")" MB"
    else
        CONSUMO=$(echo "scale=2; $BYTES/1073741824" | bc 2>/dev/null || echo "$(($BYTES/1073741824)) GB")" GB"
    fi

    LIMITE="1"
    [ -f "/etc/script_vps/limites/$username" ] && LIMITE=$(cat "/etc/script_vps/limites/$username")

    cat << BANN > "/etc/script_vps/banners/$username"
<br><br>
<font color='#00FFFF'>╔══════════════════════════════════════════════╗</font><br>
<font color='#00FFFF'>║</font><font color='#FFD700'><b>&nbsp;&nbsp;&nbsp;&nbsp;★&nbsp;&nbsp;K&nbsp;R&nbsp;A&nbsp;K&nbsp;E&nbsp;R&nbsp;&nbsp;V&nbsp;P&nbsp;N&nbsp;&nbsp;★&nbsp;&nbsp;&nbsp;&nbsp;</b></font><font color='#00FFFF'>║</font><br>
<font color='#00FFFF'>║&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Conexi&oacute;n Segura Establecida&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</font><font color='#00FFFF'>║</font><br>
<font color='#00FFFF'>╠══════════════════════════════════════════════╣</font><br>
<font color='#00FFFF'>║</font>&nbsp;<font color='#AAAAAA'>👤&nbsp;Usuario&nbsp;&nbsp;:</font>&nbsp;<font color='#00FF00'><b>&nbsp;$username</b></font><br>
<font color='#00FFFF'>║</font>&nbsp;<font color='#AAAAAA'>📅&nbsp;Expira&nbsp;&nbsp;&nbsp;:</font>&nbsp;<font color='#FFFF00'>&nbsp;$EXP_TXT</font><br>
<font color='#00FFFF'>║</font>&nbsp;<font color='#AAAAAA'>⏳&nbsp;Quedan&nbsp;&nbsp;&nbsp;:</font>&nbsp;<font color='#FF6600'><b>&nbsp;$DIAS_RESTANTES d&iacute;as</b></font><br>
<font color='#00FFFF'>║</font>&nbsp;<font color='#AAAAAA'>📊&nbsp;Consumo&nbsp;&nbsp;:</font>&nbsp;<font color='#00FFFF'><b>&nbsp;$CONSUMO</b></font><br>
<font color='#00FFFF'>║</font>&nbsp;<font color='#AAAAAA'>🔗&nbsp;IPs&nbsp;m&aacute;x&nbsp; :</font>&nbsp;<font color='#FF69B4'>&nbsp;$LIMITE conexiones</font><br>
<font color='#00FFFF'>╚══════════════════════════════════════════════╝</font><br>
<font color='#555555'>&nbsp;&nbsp;🔒&nbsp;Powered by KRAKER VPN</font><br>
<br>
BANN
done
EOF
chmod +x /usr/local/bin/kraker_consumo.sh

# Configurar en Crontab para que corra cada 1 minuto
if ! crontab -l 2>/dev/null | grep -q "kraker_consumo.sh"; then
    (crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/kraker_consumo.sh") | crontab -
fi
/usr/local/bin/kraker_consumo.sh

# Crear banner de respaldo estático global (issue.net)
cat << 'EOF' > /etc/issue.net
<br>
<font color='#00FFFF'>========================================</font><br>
<font color='#00FF00'><b>&nbsp;&nbsp;K R A K E R &nbsp;&nbsp;V P N</b></font><br>
<font color='#FFFFFF'>--- Conexión Establecida ---</font><br>
<font color='#00FFFF'>========================================</font><br>
EOF

sed -i 's/^#Banner.*/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config
sed -i 's/^Banner.*/Banner \/etc\/issue.net/g' /etc/ssh/sshd_config

# Configurar Dropbear Modificado (KRAKER)
# Si no existe el módulo (instalación por wget), lo descargamos
if [ ! -f "/etc/script_vps/modulos/install_dropbear_mod.sh" ]; then
    REPO_RAW="https://raw.githubusercontent.com/pedrorafaelcastillocalderon117-jpg/krakervps117/main"
    wget -q "$REPO_RAW/modulos/install_dropbear_mod.sh" -O /etc/script_vps/modulos/install_dropbear_mod.sh
fi
chmod +x /etc/script_vps/modulos/install_dropbear_mod.sh
/etc/script_vps/modulos/install_dropbear_mod.sh

systemctl restart sshd 2>/dev/null

echo -e "${GREEN}Instalación completada.${NC}"
echo -e "Escribe ${YELLOW}menu${NC} en la terminal para iniciar."
