##!/bin/bash

# fFORMAS DE OBTENER FICHEROS REMOTOS A LOCAL

: << 'STEPS'

Agregar tarea a nivel de usuario
--------------------------------
Fichero /etc/crontab

Agregar tarea  a nivel de sistema
---------------------------------
/etc/cron.d/  /ect/cron.[hourly|daily|weekly|monthly|yearly]/


(A) Obtener carpeta remota a local. No pide clave si el usuario local y remoto son el mismo (id y password)
scp -rp remote_username@remote_ip:/ruta/carpeta /ruta/local

Ejemplo: 
mkdir -p /home/usuario/backups
scp -rp -P 15002 usuario@192.168.1.1:/etc/cron.d /home/usuario/backups

(B) Obtener carpeta remota que se debe comprimir en remoto, el contenido contenido se transmite y se crea un fichero comprimido en local
Formato script, no olvida hacer ejecutable el fichero. Interactivo, pedirá contraseña del 'usuario':

#!/bin/bash
REMOTE_USER=usuario
REMOTE_IP=192.168.1.1
REMOTE_DIR='/etc/cron.d'
BCK_FILE=fichero-$(date + '%Y%m%d%H%M').tar
# -q no muestra el banner de conexión -o auto-acepta la host-key en primera conexión al servidor ssh
ssh -q -o StricthHostKeyChecking=accept-new {REMOTE_USER}@${REMOTE_IP} "tar -zcf - ${REMOTE_DIR}" > "${LOCAL_DIR}/${BCK_FILE}"

if [0 -eq $?}; then
  echo 'Copia realizada'
else
  echo 'Error al copiar'
fi


STEPS
