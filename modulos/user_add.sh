#!/bin/bash
# Módulo para añadir usuarios

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

clear
echo -e "${CYAN}====================================================${NC}"
echo -e "${YELLOW}               CREAR NUEVO USUARIO                  ${NC}"
echo -e "${CYAN}====================================================${NC}"

read -p "Nombre de usuario: " username
# Validar si el usuario existe
if id "$username" &>/dev/null; then
    echo -e "${RED}El usuario $username ya existe.${NC}"
    sleep 2
    exit 1
fi

read -p "Contraseña: " password
read -p "Días de validez: " dias
read -p "Límite de IPs [1]: " limite_ips
if [ -z "$limite_ips" ]; then limite_ips=1; fi

# Habilitar contraseñas en SSH por si el VPS las tiene bloqueadas
sed -i 's/^.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/50-cloud-init.conf 2>/dev/null
systemctl restart sshd
systemctl restart ssh 2>/dev/null

# Crear un shell seguro infinito para VPN con Banner Dinámico KRAKER (Formato HTML)
cat << 'EOF' > /bin/vpnshell
#!/bin/bash
clear
echo "<br>"
echo "<font color='#00FFFF'>========================================</font><br>"
echo "<font color='#00FF00'><b>&nbsp;&nbsp;K R A K E R &nbsp;&nbsp;V P N</b></font><br>"
echo "<font color='#00FFFF'>========================================</font><br>"

USUARIO=$USER
EXP_DATE=$(chage -l $USUARIO 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
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

UID_NUM=$(id -u $USUARIO 2>/dev/null)
if [ -n "$UID_NUM" ]; then
    BYTES=$(sudo /sbin/iptables-save -c 2>/dev/null | grep "uid-owner $UID_NUM" | awk -F'[:]' '{print $2}' | cut -d']' -f1 | awk '{s+=$1} END {print s}')
fi
if [ -z "$BYTES" ] || [ "$BYTES" == "" ]; then
    BYTES=0
fi

if [ $BYTES -lt 1024 ]; then
    CONSUMO="${BYTES} B"
elif [ $BYTES -lt 1048576 ]; then
    CONSUMO=$(echo "scale=2; $BYTES/1024" | bc 2>/dev/null || echo "$(($BYTES/1024)) KB")" KB"
elif [ $BYTES -lt 1073741824 ]; then
    CONSUMO=$(echo "scale=2; $BYTES/1048576" | bc 2>/dev/null || echo "$(($BYTES/1048576)) MB")" MB"
else
    CONSUMO=$(echo "scale=2; $BYTES/1073741824" | bc 2>/dev/null || echo "$(($BYTES/1073741824)) GB")" GB"
fi

if [ -f "/etc/script_vps/limites/$USUARIO" ]; then
    LIMITE=$(cat /etc/script_vps/limites/$USUARIO)
else
    LIMITE="1 (Por defecto)"
fi

echo "<font color='#FFFFFF'><b>👤 Nombre de Usuario :</b></font> <font color='#FFFF00'>$USUARIO</font><br>"
echo "<font color='#FFFFFF'><b>📅 Fecha Expiración  :</b></font> <font color='#FFFF00'>$EXP_TXT</font><br>"
echo "<font color='#FFFFFF'><b>⏳ Días Restantes    :</b></font> <font color='#FFFF00'>$DIAS_RESTANTES</font><br>"
echo "<font color='#FFFFFF'><b>📊 Consumo de datos  :</b></font> <font color='#FFFF00'>$CONSUMO</font><br>"
echo "<font color='#FFFFFF'><b>🔗 Límite de IPs     :</b></font> <font color='#FFFF00'>$LIMITE</font><br>"
echo "<font color='#00FFFF'>========================================</font><br>"

# Para clientes que no soportan HTML (como Termux), imprimimos texto limpio también
echo -e "\n--- Bienvenido $USUARIO a KRAKER VPN ---"
echo -e "Expira: $EXP_TXT ($DIAS_RESTANTES días) | Consumo: $CONSUMO | IPs: $LIMITE\n"

while true; do sleep 86400; done
EOF
chmod +x /bin/vpnshell
if ! grep -q "/bin/vpnshell" /etc/shells 2>/dev/null; then
    echo "/bin/vpnshell" >> /etc/shells
fi

# Crear el usuario sin directorio y con el shell infinito
useradd -M -s /bin/vpnshell "$username"
echo "$username:$password" | chpasswd

# Guardar límite de IPs
mkdir -p /etc/script_vps/limites
echo "$limite_ips" > "/etc/script_vps/limites/$username"

# Regla de iptables para consumo
if ! iptables -C OUTPUT -m owner --uid-owner "$username" -j ACCEPT 2>/dev/null; then
    iptables -A OUTPUT -m owner --uid-owner "$username" -j ACCEPT
fi

# Calcular la fecha de expiración
if [[ "$dias" =~ ^[0-9]+$ ]]; then
    expdate=$(date "+%F" -d "+$dias days")
    chage -E "$expdate" "$username"
    echo -e "${GREEN}Usuario creado exitosamente.${NC}"
    echo -e "Usuario: $username"
    echo -e "Contraseña: $password"
    echo -e "Expira: $expdate ($dias días)"
else
    echo -e "${RED}Cantidad de días inválida, el usuario no expirará automáticamente.${NC}"
    echo -e "${GREEN}Usuario creado exitosamente.${NC}"
fi

echo -e "${CYAN}====================================================${NC}"
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
