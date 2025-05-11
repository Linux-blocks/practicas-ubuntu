##!/bin/sh

: << 'COMMENT'
Objetivo: Compartir la carpeta shared_folder de [R]
Acceso mediante usuario: shared_user

COMMENT

# INSTALAR SAMBA
sudo apt update
sudo apt list | grep samba
sudo apt install samba -y
# comprobar instalación correcta. Mostrará carpetas 
whereis samba
systemctl status smbd

# CONFIGURAR EL SERVIDOR SAMBA
# editar /etc/samba/smb.conf
: << 'COMMENT'
Añadir al final una sección para la carpeta a compartir:
[shared_folder]
path = /home/<username>/shared_folder
readonly = no
browsable = yes
#valid users = <username>
COMMENT

# comprobar sintáxis y aplicar configuración

sudo systemctl reload smbd

# PERMITIR COMUNICACIÓN ENTRANTE CON EL SAMBA
sudo ufw allow samba

# CREAR O AÑADIR USUARIO DE ACCESO
# samba usa su propio sistema de autenticación (tbdsam: /usr/local/samba/private/passdb.tdb
# Crear requiere hacerlo en el Sistema y en Samba
sudo adduser --no-create-home --shell /usr/sbin/nologin --user-group <username>
sudo smbpasswd -a <username>

# CREAR, si necesario, LA CARPETA A COMPARTIR
mkdir ~/shared_folder/  # o también en /srv/shared_folder/

# ACLs de la carpeta compartida (opcional)


# prueba de acceso desde linux
## smb://<server_ip>
# prueba de acceso desde windows
## \\server_ip_or_dns\shared_folder
