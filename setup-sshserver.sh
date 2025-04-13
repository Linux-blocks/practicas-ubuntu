##!/bin/sh

# NO EJECUTAR. NO ES UN SCRIPT. ES UNA GUÍA DE COMANDOS A EJECUTAR INTERACTIVAMENTE
# =================================================================================

: << 'COMMENT'
    Este fichero no es un script. 
    Contiene secuencias de comandos a ejecutar interactivamente en el terminal
    Objetivos: 
    (1) Instalarlo si no lo estuviera. En [R:192.168.1.1]
    (2) Configurar servicio: Puerto personalizado: 15022
        No permitir sesión como root. Solo usuario:  "usuario". 
        Autenticación por contraseña.
    Se necesita tener creados usuario y usuariofoo en R y clientes
    echo usuariofoo:foopass | sudo chpasswd
    ! OJO: Ubuntu server 24 LTS.
COMMENT

# INSTALAR SERVIDOR SSH, si no estuviera ya instalado
sudo apt update
sudo apt list | grep ssh
sudo apt install openssh-server

# CONFIGURAR
: << COMMENT
  OJO: Comprobar configs en sshd_config,d/*.conf
  Lo contenido tiene preferencia sobre sshd_config.
  Si se configura desde remoto, mantener otra sesión abierta hasta verificar conectividad 
  y no quedarse bloqueado, con usuario con permisos sudo.
COMMENT
# Se prefiere config en fichero aparte, dentro carpeta sshd_config.d en vez de editar sshd_config:
cd /etc/ssh
sudo tee > sshd_config.d/00-custom.conf << 'EOF'
Port 15022
EOF

: << 'COMMENT'
Desde Ubuntu 22 la conexión ssh tiene un servicio socket.ssh interpuesto al servicio ssh. 
Así, para aplicar cambios de configuración hay que: recargar system manager config (systemd files)
y reiniciar el servicio ssh.socket.
Motivo de ssh.socket: Ahorra RAM al activar ssh solo cuando llega una conexión. 
Para volver a config estándar: 
systemctl disable --now ssh.socket && systemctl enable --now ssh.service
COMMENT
# REINICIAR SERVICIOS PARA APLICAR, según classic o modern ssh config
# comprobar sintáxis de ficheros conf. No muestra nada si OK
sshd -t
#sudo systemctl restart ssh
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket

# COMPROBAR FUNCIONAMIENTO
# verificar puerto a la escucha
ss -tulpan
# Comprobar conexión con password y puerto desde un cliente:
ssh -p 15022 usuario@192.168.1.1

: << 'FEATURE'
CONFIGURAR AUTENTICACIÓN DE CLAVE PÚBLICA
Este es un subejercicio opcional. Permite un nivel adicional de seguridad usando algo que se tiene (cert) y algo que se sabe (password). Pasos: 
    (1) Generar el par de claves en el cliente, usando el usuario  'usuario', contraseña  y algoritmo ed25519 (desde ubuntu 22 no se soporta RSA).
    (2) Copiar la clave pública en el servidor ssh.
    (3) Habilitar esta autenticación ssh en el servidor. Si se modifica la config, reiniciar para aplicar.
    (4) Probar conectar con esta autenticación.
FEATURE

# (1) CREAR KEYS EN R o en un cliente
# Nota: se pueden crear en windows si linux subsystem habilitado
#ssh-keygen -t rsa -b 4096 -N 'usuario-lkey' -f "~/.ssh/usuario_router_rsakey" -C "Usuario-router-rsakey"
sudo ssh-keygen -t ed25519 -N 'usuario-key' -f "~/.ssh/usuario_router_edkey" -C "usuario-router-edkey"

# Crear e instalar keys para Usuariofoo. Pero no instalar pubkey en R
#ssh-keygen -t rsa -b 4096 -N 'usuariofoo-lkey' -f "~/.ssh/usuariofoo_router_rsakey" -C "Usuariofoo-router-rsakey"
sudo ssh-keygen -t ed25519 -N 'usuariofoo-key' -f "/home/usuariofoo/.ssh/usuariofoo_router_edkey" -C "usuariofoo-router-edkey"
#ssh-copy-id -i usuario_foorouter_edkey -p 15022 usuariofoo@192.168.1.1

# opc: añadir la clave a ssh-agent (un llavero) para usar sin pedir clave. P.e, en automatización
# comprobar si está instalado y en ejecución
#eval $(ssh-agent)
#sudo ssh-add ~/.ssh/usuario-router-edkey

# (2) INSTALAR PUB KEY EN R
# añade la clave pública al fichero ~/.ssh/authorized_keys de usuario
cd ~/.ssh
ssh-copy-id -i ~/.ssh/usuario_router_edkey -p 15022 usuario@192.168.1.1

# (3) HABILITAR AUTH CON KEYS
#nano /etc/ssh/sshd_config.d/00-custom.conf
sudo tee >> sshd_config.d/00-custom.conf << 'EOF'
PubkeyAuthentication yes
EOF

# (4) COMPROBAR FUNCIONAMIENTO
ssh -v -i router_ubuntu_edkey -p 15022 usuario@192.168.1.1

: << 'FEATURE'
CONFIGURAR PERMISOS PARA GRUPOS
Acceso más granular
FEATURE
# Crear un grupo de acceso por ssh y añadirle 'usuario'
sudo groupadd gr_ssh
usermod -aG gr_ssh usuario

# admitir a los usuarios del grupo gr_ssh
#nano /etc/ssh/sshd_config.d/00-custom.conf
sudo tee >> sshd_config.d/00-custom.conf << 'EOF'
# Orden de precedencia: Intersección de DenyUsers - AllowUsers - DenyGroups - AllowGroups
AllowGroups gr_ssh
EOF

# reiniciar servicio para aplicar, según classic o modern ssh config
sshd -t
#sudo systemctl restart ssh
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket

# COMPROBAR FUNCIONAMIENTO
# acceso desde cliente remoto
ssh -p 15022 usuario@192.168.1.1
ssh -p 15022 usuariofoo@192.168.1.1
