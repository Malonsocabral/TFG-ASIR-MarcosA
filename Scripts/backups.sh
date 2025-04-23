#!/bin/bash  # Intérprete Bash

# CONFIGURACIÓN BÁSICA
REPO="/mnt/backups/borg_nextcloud"  # Carpeta única de backup Borg (repositorio)
SOURCE="/var/lib/docker/volumes/nextcloud_data"  # Directorio que quiero respaldar
LOG="/var/log/nextcloud_backup.log"  # Archivo de log para registrar eventos
SCRIPT_PATH="$(realpath "$0")"  # Ruta absoluta del script, para añadirlo a cron
PASSPHRASE="tu_clave_secreta"  # Clave para cifrar el repositorio (guárdala segura)

export BORG_REPO=$REPO  # Indico a Borg dónde está el repositorio
export BORG_PASSPHRASE=$PASSPHRASE  # Le paso la clave para el cifrado

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)  # Timestamp único para cada snapshot

# FUNCION PARA LOGS
log() {
    echo "[$(date)] $1" >> $LOG  # Imprime mensajes con marca de tiempo
}

# AÑADIR ENTRADA A CRONTAB SI NO EXISTE
CRON_ENTRY="0 */12 * * * $SCRIPT_PATH"  # Ejecutar cada 12 horas
(crontab -l 2>/dev/null | grep -F "$SCRIPT_PATH") >/dev/null || {
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    log "Entrada de cron añadida automáticamente: '$CRON_ENTRY'"
}

# CREAR REPOSITORIO BORG SI NO EXISTE
if [ ! -d "$REPO" ]; then
    log "Repositorio no encontrado. Inicializando uno nuevo..."
    borg init --encryption=repokey-blake2 $REPO >> $LOG 2>&1
fi

# DETENER NEXTCLOUD PARA CONSISTENCIA
log "Deteniendo contenedor Nextcloud..."
docker stop nextcloud >> $LOG 2>&1

# CREAR BACKUP INCREMENTAL EN EL REPOSITORIO
log "Creando snapshot: $TIMESTAMP"
borg create --stats --compression lz4 \
    ::nextcloud-$TIMESTAMP $SOURCE >> $LOG 2>&1

# REINICIAR CONTENEDOR
log "Reiniciando contenedor Nextcloud..."
docker start nextcloud >> $LOG 2>&1

# ELIMINAR SNAPSHOTS ANTIGUOS PARA AHORRAR ESPACIO
log "Aplicando política de retención de backups..."
borg prune --list --keep-daily=7 --keep-weekly=4 --keep-monthly=6 >> $LOG 2>&1

# LOG FINAL
log "Backup incremental completado correctamente."
