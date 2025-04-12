##!/bin/sh

: << COMMENT
    Este fichero no es un script. 
    Contiene secuencias de comandos a ejecutar interactivamente en el terminal
    Objetivos: 
    (1) Instalarlo si no estuviera. En [R:192.168.1.1] y [SWEB:192.168.2.10]
    (2) Configurar servicio: Puerto personalizado: 15022
        No permitir sesión como root. Solo usuario:  "usuario". 
        Autenticación por contraseña.
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
sudo tee > sshd_config.d/00-custom-port.conf << 'EOF'
Port 15022
EOF

: << 'COMMENT'
Desde Ubuntu 22 sshd es gobernado por un servicio ayudante: ssh.socket
Así, no hay que reload|restart ssh para aplicar sino daemon-reload y ssh.socket
COMMENT
# REINICIAR SERVICIOS PARA APLICAR CONFIG y comprobar conexión
# comprobar sintáxis de ficheros conf. No muestra nada si OK
sshd -t
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
# verificar puerto a la escucha, viendo todos listen y established
ss -tulpn
# Comprobar conexión con password y puerto desde un cliente:
ssh -p 15022 usuario@192.168.1.1

: << 'COMMENT'
Desde Ubuntu 22 la conexión ssh tiene un servicio socket.ssh interpuesto al servicio ssh. Resultando que ListenAddress y Port en los *.conf no se aplican. Se aplican otras config de socket.ssh.
Motivo: socket.ssh ahorra RAM al activar ssh solo cuando llega una conexión. Para volver a config estándar: systemctl disable --now ssh.socket && systemctl enable --now ssh.service
COMMENT
Configurar autenticación clave pública
Este es un subejercicio opcional. Permite un nivel adicional de seguridad usando algo que se tiene (cert) y algo que se sabe (password). Pasos: 
    (1) Generar el par de claves en el cliente, usando el usuario  'usuario', contraseña  y algoritmo ed25519 (desde ubuntu 22 no se soporta RSA).
    (2) Copiar la clave pública en el servidor ssh.
    (3) Habilitar esta autenticación ssh en el servidor. Si se modifica la config, reiniciar para aplicar.
    (4) Probar conectar con esta autenticación.

# (1) Crear el par en el pc cliente
# Con -N se indica contraseña de uso
ssh-keygen -t ed25519 -N 'Usuarionping' -f "~/.ssh/router_ubuntu_edkey"

# (2) copiar la clave pública al servidor
# Aunque tenga config publickey 
# se puede usar password para copiarla
# NO sobreescribe claves, solo añade !!
cd ~/.ssh
ssh-copy-id -i router_ubuntu_edkey -p 22422 usuario@192.168.1.1

# (4) probar conexión con clave pública
# Se pide contraseña de cert, si OK se
# entra en la consola del servidor
# sin usar la autenticación por contraseña
ssh -i router_ubuntu_edkey -p 15022 usuario@192.168.1.1
Permisos por usuarios y grupos
Subejercicio opcional. Permite configurar acceso más  granular mediante varias directivas. 
# Crear el grupo y añadirle 'usuario'
sudo groupadd gr_ssh
usermod -aG gr_ssh usuario

# admitir a los usuarios del grupo ssh
nano /etc/ssh/sshd_config.d/00-custom.conf
AllowGroups gr_ssh
# reiniciar servicio para aplicar
sudo systemctl restart ssh

Verificar que solo usuarios del gr_ssh pueden acceder al servidor. Para ello creamos un usuario de prueba.
# Crear usuario nuevo de prueba
sudo useradd foouser
# Se ha creado sin password, asignarla
# porque con PermitEmptyPassword no
# no se podría acceder sin ella
sudo passwd foouser

# e intentamos acceder desde cliente remoto
# debiendo denegarnos el acceso
ssh -p 22422 foouser@192.168.1.1
