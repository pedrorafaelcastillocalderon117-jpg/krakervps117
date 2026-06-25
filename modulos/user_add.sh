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

# Habilitar contraseñas en SSH por si el VPS las tiene bloqueadas
sed -i 's/^.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/^.*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config.d/50-cloud-init.conf 2>/dev/null
systemctl restart sshd
systemctl restart ssh 2>/dev/null

# Crear un shell seguro infinito para VPN (evita que SSH desconecte y no da acceso a la consola)
if [ ! -f /bin/vpnshell ]; then
    echo -e '#!/bin/bash\nwhile true; do sleep 86400; done' > /bin/vpnshell
    chmod +x /bin/vpnshell
    echo "/bin/vpnshell" >> /etc/shells
fi

# Crear el usuario sin directorio y con el shell infinito
useradd -M -s /bin/vpnshell "$username"
echo "$username:$password" | chpasswd

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
