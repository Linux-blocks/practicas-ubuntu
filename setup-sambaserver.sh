##!/bin/sh

: << 'COMMENT'
Objetivo: Compartir la carpeta shared_folder de [R]
Acceso mediante usuario: shared_user

COMMENT

# INSTALAR SAMBA
sudo apt update
# comprobar si instalado
sudo apt list | grep samba
# instalar. Añade samba-common samba-common-bin samba-libs samba-ad-provision y otros samba-*
sudo apt install samba -y
# comprobar instalación correcta. Mostrará carpetas 
whereis samba
systemctl status smbd
sudo ss -tulpn   # puertos usados por smbd: 0.0.0.0 445, 139

# CONFIGURAR EL SERVIDOR SAMBA
# editar /etc/samba/smb.conf tras hacer copia del original
sudo cp /etc/smb/smb.conf /etc/smb/smb.conf.default
: << 'COMMENT'
Añadir al final una sección para la carpeta a compartir:
# cuando se cambia la contraseña en samba, se intenta sincronizar la del usuario en el sistem
#unix password sync = yes

[shared_folder]
path = /home/<username>/shared_folder
readonly = no
browsable = yes
#valid users = <username>
COMMENT

# comprobar sintáxis y aplicar configuración
tstparm
# aplicar los cambios
# Nota: El warning "Referenced but unser environment variable ..." se puede ignorar con seguridad
sudo systemctl reload smbd

# PERMITIR COMUNICACIÓN ENTRANTE CON EL SAMBA
# ver fichero con reglas de iptables
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
