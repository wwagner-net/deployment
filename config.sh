#!/bin/bash
# Konfiguration für TYPO3-Synchronisierungstool

# SSH-Zugangsdaten
REMOTE_HOST=""

# Datenbank-Zugangsdaten
DB_HOST=""
DB_USER=""
DB_PASS=''
DB_NAME=""

# Pfade
BASE_PATH=""
SHARED_PATH="$BASE_PATH/shared"
FILEADMIN_REMOTE="$SHARED_PATH/public/fileadmin/"
FILEADMIN_LOCAL="public/fileadmin/"
