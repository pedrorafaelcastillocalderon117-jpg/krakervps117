#!/bin/bash
# install_websocket.sh - Instala un Proxy en Python para conexiones WebSocket + Payload y SSL Directo

echo -e "\e[1;32mInstalando Proxy WebSocket Inteligente (Multiplexor)...\e[0m"

# Asegurar que python3 está instalado
if ! command -v python3 &> /dev/null; then
    apt-get update
    apt-get install -y python3
fi

# Crear directorio
mkdir -p /etc/websocket

# Crear el script de Python
cat << 'EOF' > /etc/websocket/proxy.py
import socket, threading, sys

def handle_client(client_socket, target_host, target_port):
    try:
        # Recibir la primera peticion del cliente
        request = client_socket.recv(4096)
        if not request:
            client_socket.close()
            return
            
        target_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        target_socket.connect((target_host, target_port))
        
        # Comprobar si la conexion inicia con una cabecera HTTP (es decir, es un Payload o WebSocket)
        http_methods = (b'GET ', b'POST ', b'HTTP/', b'CONNECT ', b'PUT ', b'OPTIONS ', b'HEAD ')
        is_http = request.startswith(http_methods)
        
        if is_http:
            # Es una conexion con PAYLOAD: Simulamos la respuesta WebSocket
            response = "HTTP/1.1 101 Switching Protocols\r\n"
            response += "Upgrade: websocket\r\n"
            response += "Connection: Upgrade\r\n\r\n"
            client_socket.sendall(response.encode('utf-8'))
            
            # Si el payload traia datos extra despues de las cabeceras, se los mandamos al SSH
            if b'\r\n\r\n' in request:
                residual = request.split(b'\r\n\r\n', 1)[1]
                if residual:
                    target_socket.sendall(residual)
        else:
            # Es una conexion de SSL/SSH PURO (Sin Payload): 
            # No respondemos nada de HTTP, enviamos el trafico directo al SSH
            target_socket.sendall(request)

        # Iniciar hilos para reenviar los datos
        t1 = threading.Thread(target=forward, args=(client_socket, target_socket))
        t2 = threading.Thread(target=forward, args=(target_socket, client_socket))
        t1.start()
        t2.start()
        t1.join()
        t2.join()
    except Exception as e:
        pass
    finally:
        try: client_socket.close() 
        except: pass

def forward(source, destination):
    try:
        while True:
            data = source.recv(4096)
            if not data:
                break
            destination.sendall(data)
    except:
        pass
    finally:
        try: source.close() 
        except: pass
        try: destination.close() 
        except: pass

if __name__ == '__main__':
    listen_port = 8080 # Puerto Multiplexor
    target_port = 22 # Puerto Destino
    
    if len(sys.argv) > 1:
        listen_port = int(sys.argv[1])
    if len(sys.argv) > 2:
        target_port = int(sys.argv[2])
        
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', listen_port))
    server.listen(100)
    print(f"Proxy Multiplexor escuchando en {listen_port} -> redirigiendo a {target_port}")
    
    while True:
        try:
            client_socket, addr = server.accept()
            client_thread = threading.Thread(target=handle_client, args=(client_socket, '127.0.0.1', target_port))
            client_thread.start()
        except:
            pass
EOF

chmod +x /etc/websocket/proxy.py

# Crear el servicio de systemd
cat << 'EOF' > /etc/systemd/system/ws-proxy.service
[Unit]
Description=Proxy WebSocket Python para VPN/SSH
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /etc/websocket/proxy.py 8080 22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Iniciar el servicio
systemctl daemon-reload
systemctl enable ws-proxy
systemctl restart ws-proxy

echo -e "\e[1;32m¡Módulo WebSocket Multiplexor instalado exitosamente!\e[0m"
