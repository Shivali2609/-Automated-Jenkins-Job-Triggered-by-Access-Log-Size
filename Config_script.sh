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

WEBHOOK_URL="https://webhook.site/your-unique-url"s