#!/usr/local/bin/bash -C

LOCK_FILE=/tmp/backup-media.pid
RSYNC_BIN=/usr/local/bin/rsync
SSH_BIN=/usr/bin/ssh
RSYNC_LOG_FILE=${HOME}/rsync.log
RSYNC_EXCLUDE_PATTERNS_FILE=${HOME}/.rsync/exclude
REMOTE_PORT=
REMOTE_USER=
REMOTE_HOST=
REMOTE_PATH=/c/media
LOCAL_PATH=/backup

if [ -e "${LOCK_FILE}" ]; then
        if pgrep -F $LOCK_FILE > /dev/null; then
                PID=$(cat ${LOCK_FILE})
                echo "Backup still in progress with PID ${PID}, exiting."
                exit 1
        else
                # Clean up previous lock file
                rm -f ${LOCK_FILE}
        fi
fi

trap "rm -f ${LOCK_FILE}; exit $?" INT TERM EXIT
echo "$$" > ${LOCK_FILE}

${RSYNC_BIN} -avs -P --stats --delete --log-file=${RSYNC_LOG_FILE} --exclude-from=${RSYNC_EXCLUDE_PATTERNS_FILE} -e "${SSH_BIN} -p ${REMOTE_PORT}" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH} ${LOCAL_PATH} &> /dev/null

exit 0
