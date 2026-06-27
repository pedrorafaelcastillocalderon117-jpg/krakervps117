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
cp menu.sh /etc/script_vps/menu.sh
cp -r modulos/* /etc/script_vps/modulos/ 2>/dev/null

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
for user_conf in /etc/ssh/sshd_config.d/banner_*.conf; do
    [ -e "$user_conf" ] || continue
    username=$(basename "$user_conf" | sed 's/banner_//;s/\.conf//')
    
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
    BYTES=0
    if [ -n "$UID_NUM" ]; then
        BYTES=$(grep "uid-owner $UID_NUM" /etc/script_vps/consumos.txt | awk -F'[:]' '{print $2}' | cut -d']' -f1 | awk '{s+=$1} END {print s}')
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
<br>
<font color='#00FFFF'>========================================</font><br>
<font color='#00FF00'><b>&nbsp;&nbsp;K R A K E R &nbsp;&nbsp;V P N</b></font><br>
<font color='#00FFFF'>========================================</font><br>
<font color='#FFFFFF'><b>👤 Usuario:</b></font> <font color='#FFFF00'>$username</font><br>
<font color='#FFFFFF'><b>📅 Expira :</b></font> <font color='#FFFF00'>$EXP_TXT</font><br>
<font color='#FFFFFF'><b>⏳ Quedan :</b></font> <font color='#FFFF00'>$DIAS_RESTANTES días</font><br>
<font color='#FFFFFF'><b>📊 Consumo:</b></font> <font color='#FFFF00'>$CONSUMO</font><br>
<font color='#FFFFFF'><b>🔗 IPs    :</b></font> <font color='#FFFF00'>$LIMITE</font><br>
<font color='#00FFFF'>========================================</font><br>
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
chmod +x /etc/script_vps/modulos/install_dropbear_mod.sh
/etc/script_vps/modulos/install_dropbear_mod.sh

systemctl restart sshd 2>/dev/null

echo -e "${GREEN}Instalación completada.${NC}"
echo -e "Escribe ${YELLOW}menu${NC} en la terminal para iniciar."
