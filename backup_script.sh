#!/bin/bash

# ---------------- CONFIGURATION ----------------

PROJECT_NAME="project3"
SOURCE_DIR="$HOME/project3"
BASE_BACKUP_DIR="$HOME/backups"
GDRIVE_REMOTE="gdrive:Backups/$PROJECT_NAME"
LOG_FILE="$HOME/backup.log"

# Retention Settings
DAILY_RETENTION=7
WEEKLY_RETENTION=4
MONTHLY_RETENTION=3

WEBHOOK_URL="https://webhook.site/your-unique-url"

# ---------------- ARGUMENTS ----------------

NO_NOTIFY=false
if [[ "$1" == "--no-notify" ]]; then
  NO_NOTIFY=true
fi

# ---------------- PREPARE DIRECTORIES ----------------

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
YEAR=$(date +"%Y")
MONTH=$(date +"%m")
DAY=$(date +"%d")

BACKUP_DIR="$BASE_BACKUP_DIR/$PROJECT_NAME/$YEAR/$MONTH/$DAY"
mkdir -p "$BACKUP_DIR"

BACKUP_FILE="${PROJECT_NAME}_${TIMESTAMP}.zip"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

# ---------------- CREATE BACKUP ----------------

zip -r "$BACKUP_PATH" "$SOURCE_DIR" >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "[$(date)] Backup failed" >> "$LOG_FILE"
  exit 1
fi

echo "[$(date)] Created backup: $BACKUP_FILE" >> "$LOG_FILE"

# ---------------- UPLOAD TO GOOGLE DRIVE ----------------

rclone copy "$BACKUP_PATH" "$GDRIVE_REMOTE" >/dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "[$(date)] Upload successful" >> "$LOG_FILE"
else
  echo "[$(date)] Upload failed" >> "$LOG_FILE"
  exit 1
fi

# ---------------- ROTATION LOGIC ----------------

BACKUP_ROOT="$BASE_BACKUP_DIR/$PROJECT_NAME"

# Daily retention
find "$BACKUP_ROOT" -type f -name "*.zip" -mtime +$DAILY_RETENTION -delete
echo "[$(date)] Daily retention cleanup done" >> "$LOG_FILE"

# Weekly retention (Sundays)
mapfile -t WEEKLY_FILES < <(
  find "$BACKUP_ROOT" -type f -name "*.zip" | sort -r | while read f; do
    [ "$(date -r "$f" +%u)" -eq 7 ] && echo "$f"
  done
)

for ((i=$WEEKLY_RETENTION; i<${#WEEKLY_FILES[@]}; i++)); do
  rm -f "${WEEKLY_FILES[$i]}"
done
echo "[$(date)] Weekly retention cleanup done" >> "$LOG_FILE"

# Monthly retention (1st day)
mapfile -t MONTHLY_FILES < <(
  find "$BACKUP_ROOT" -type f -name "*.zip" | sort -r | while read f; do
    [ "$(date -r "$f" +%d)" -eq 01 ] && echo "$f"
  done
)

for ((i=$MONTHLY_RETENTION; i<${#MONTHLY_FILES[@]}; i++)); do
  rm -f "${MONTHLY_FILES[$i]}"
done
echo "[$(date)] Monthly retention cleanup done" >> "$LOG_FILE"

# ---------------- NOTIFICATION ----------------

if [ "$NO_NOTIFY" = false ]; then
  curl -X POST -H "Content-Type: application/json" \
  -d "{\"project\": \"$PROJECT_NAME\", \"date\": \"$TIMESTAMP\", \"status\": \"BackupSuccessful\"}" \
  "$WEBHOOK_URL" >/dev/null 2>&1

  echo "[$(date)] Notification sent" >> "$LOG_FILE"
fi

echo "[$(date)] Backup completed successfully" >> "$LOG_FILE"
