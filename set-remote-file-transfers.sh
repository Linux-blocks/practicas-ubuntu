
############### TAREAS ###############
Obtener ficheros de sistemas remotos.
1.Comando scp para obtener carpeta remota con scp
2. Script para comprimir y obtener una carpeta remota a una local, con ssh
3. Crear cron para ejecutar 2 como tarea programada

############### OBTENER CARPERTA REMOTA CON SCP ###############
# El sistema remoto debe tener un servidor ssh. No olvidar hacerlo ejecutable: chmod +x /path/script.sh
REMOTE_USER=usuario
REMOTE_IP=192.168.1.1
REMOTE_DIR='/etc/cron.d'
LOCAL_DIR=/home/usuario/bck
# -r recurse, -p persistir atributos, -B equivale a BatchMode=true (si passwordless no activado, termina con error)
scp -rp -P 15002 -B ${REMOTE_USER}@${REMOTE_IP}:${REMOTE_DIR} ${LOCAL_DIR} 
if [0 -eq $?]; then
  echo 'Copia realizada'
else
  echo 'Error al copiar'
fi

############### OBTENER CARPETA COMPRIMIDA CON SSH (script) ###############
# El sistema remoto debe tener un servidor ssh. No olvidar hacerlo ejecutable: chmod +x /path/script.sh
# La carpeta comprimida obtenida tiene nombre dinámico con fecha y hora.
REMOTE_USER=usuario
REMOTE_IP=192.168.1.1
REMOTE_DIR='/etc/cron.d'
LOCAL_DIR=/home/usuario/bck
BCK_FILE=fichero-$(date + '%Y%m%d%H%M').tar
# -q no muestra el banner de conexión, -o auto-acepta la host-key en primera conexión al servidor ssh
# -z comprime en gz
ssh -q -p 15002 -o BatchMode=true -o StricthHostKeyChecking=accept-new {REMOTE_USER}@${REMOTE_IP} "tar -czf - ${REMOTE_DIR}" > "${LOCAL_DIR}/${BCK_FILE}"
if [0 -eq $?]; then
  echo 'Copia realizada'
else
  echo 'Error al copiar'
fi

############### CREAR CRON DE SCRIPT) ###############
# formato tarea: m h month-day month weekday command
# cron tutorial: https://www.hostinger.com/es/tutoriales/cron-job
# -e interactivo. 
# add job vía scripting: crontabcont
crontab -e      # abre el editor de crons del usuario actual. Añadir -u <username> para el de uno en concreto
: << 'CONTENIDO'
5  0  *  *  *  /home/usuario/backup.sh >> /home/backups.log
CONTENIDO

# comprobar contenido para usuario actual
crontab -l   # [-u <username>]

: << 'STEPS'

Agregar tarea a nivel de usuario
--------------------------------
/var/spool/cron/crontabs/<username>

Agregar tarea  a nivel de sistema
---------------------------------
/etc/cron.d/  /ect/cron.[hourly|daily|weekly|monthly|yearly]/
/etc/crontab  Incluye un campo añadido min hour day month wday <username> script|command
              Incluye runs para cada .hourly daily weekly monthly ...
STEPS
