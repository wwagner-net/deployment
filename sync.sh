
#!/bin/bash
# sync.sh

# Prüfe, ob die Konfigurationsdatei existiert
CONFIG_FILE=$(dirname "$0")/config.sh
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Fehler: Konfigurationsdatei nicht gefunden: $CONFIG_FILE"
    echo "Bitte erstellen Sie die Datei basierend auf config.example.sh"
    exit 1
fi

# Konfiguration laden
source "$CONFIG_FILE"

# Hilfsfunktion für Fehlerbehandlung
function check_error {
    if [ $? -ne 0 ]; then
        echo "Fehler: $1"
        return 1
    fi
    return 0
}

# Funktion für Datenbank-Import
function fetch_database {
    echo "Prüfe SSH-Verbindung zu $REMOTE_HOST..."
    if ! ssh -q $REMOTE_HOST exit; then
        echo "Fehler: Keine SSH-Verbindung zu $REMOTE_HOST möglich."
        return 1
    fi

    echo "Hole Datenbank vom Produktionsserver..."
    ssh $REMOTE_HOST "mysqldump --opt --no-tablespaces -h $DB_HOST -u $DB_USER -p'$DB_PASS' $DB_NAME" > dump.sql
    if ! check_error "Erstellen des Dumps fehlgeschlagen"; then
        return 1
    fi

    echo "Importiere Dump in lokale Datenbank..."
    ddev import-db < dump.sql && rm -f dump.sql
    if ! check_error "Importieren des Dumps fehlgeschlagen"; then
        return 1
    fi

    echo "Aktualisiere Datenbankschema..."
    ddev typo3 database:updateschema '*.add,*.change'
    if ! check_error "Aktualisieren des Datenbankschemas fehlgeschlagen"; then
        return 1
    fi

    echo "Datenbank erfolgreich synchronisiert."
    return 0
}

# Funktion für Fileadmin-Import
function fetch_fileadmin {
    echo "Prüfe SSH-Verbindung zu $REMOTE_HOST..."
    if ! ssh -q $REMOTE_HOST exit; then
        echo "Fehler: Keine SSH-Verbindung zu $REMOTE_HOST möglich."
        return 1
    fi

    # Prüfe, ob Quellordner existiert
    echo "Prüfe Remote-Verzeichnis..."
    if ! ssh $REMOTE_HOST "[ -d '$FILEADMIN_REMOTE' ]"; then
        echo "Fehler: Der Quellordner $FILEADMIN_REMOTE existiert nicht auf dem Remote-Host."
        return 1
    fi

    # Stelle sicher, dass lokales Verzeichnis existiert
    if [ ! -d "$FILEADMIN_LOCAL" ]; then
        mkdir -p "$FILEADMIN_LOCAL"
        echo "Lokales Verzeichnis $FILEADMIN_LOCAL erstellt."
    fi

    echo "Hole Fileadmin-Dateien vom Produktionsserver..."
    rsync -avz $REMOTE_HOST:"$FILEADMIN_REMOTE" "$FILEADMIN_LOCAL"
    if ! check_error "rsync-Übertragung fehlgeschlagen"; then
        return 1
    fi

    echo "Fileadmin-Dateien erfolgreich synchronisiert."
    return 0
}


# Funktion für Fileadmin-Export zum Produktionsserver
function push_fileadmin {
    # Parameter für Simulationsmodus prüfen
    local DRY_RUN=""
    if [ "$1" = "--dry-run" ] || [ "$1" = "-n" ]; then
        DRY_RUN="--dry-run"
        echo "SIMULATIONSMODUS: Es werden keine Dateien übertragen."
    else
        # Sicherheitsabfrage nur bei echtem Upload, nicht bei Dry-Run
        echo "⚠️ ACHTUNG: Du willst lokale Fileadmin-Dateien auf den Produktionsserver übertragen."
        echo "⚠️ Neue Dateien werden hinzugefügt, existierende Dateien bleiben unverändert."
        echo ""
        read -p "Bist du sicher, dass du fortfahren möchtest? (j/N) " confirmation
        confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

        if [[ "$confirmation" != "j" && "$confirmation" != "ja" ]]; then
            echo "Aktion abgebrochen."
            return 0
        fi
    fi

    echo "Lade Fileadmin-Dateien auf den Produktionsserver hoch..."

    # Prüfe SSH-Verbindung
    echo "Prüfe SSH-Verbindung zu $REMOTE_HOST..."
    if ! ssh -q $REMOTE_HOST exit; then
        echo "Fehler: Keine SSH-Verbindung zu $REMOTE_HOST möglich."
        return 1
    fi

    # Prüfe, ob lokaler Ordner existiert
    if [ ! -d "$FILEADMIN_LOCAL" ]; then
        echo "Fehler: Der lokale Ordner $FILEADMIN_LOCAL existiert nicht."
        return 1
    fi

    # Prüfe, ob Remote-Ordner existiert
    echo "Prüfe Remote-Verzeichnis..."
    if ! ssh $REMOTE_HOST "[ -d '$FILEADMIN_REMOTE' ]"; then
        echo "Fehler: Der Remote-Ordner $FILEADMIN_REMOTE existiert nicht auf dem Remote-Host."
        return 1
    fi

    echo "Lade Fileadmin-Dateien hoch..."
    # --ignore-existing: Existierende Dateien nicht überschreiben
    # --existing: Nur Dateien aktualisieren, die bereits auf dem Ziel vorhanden sind (auskommentiert für Upload neuer Dateien)
    rsync -avz $DRY_RUN --ignore-existing --exclude="_processed_/" --exclude="_temp_/" "$FILEADMIN_LOCAL" $REMOTE_HOST:"$FILEADMIN_REMOTE"

    local RSYNC_STATUS=$?
    if [ $RSYNC_STATUS -ne 0 ]; then
        echo "Fehler bei rsync (Status-Code: $RSYNC_STATUS)"
        return 1
    fi

    if [ "$DRY_RUN" = "--dry-run" ]; then
        echo "SIMULATIONSMODUS beendet. Keine Dateien wurden übertragen."
        echo "Führe den Befehl ohne --dry-run aus, um die Dateien tatsächlich zu übertragen."
    else
        echo "Fileadmin-Dateien erfolgreich auf den Produktionsserver hochgeladen."
    fi

    return 0
}

# Funktion für Datenbank-Export zum Produktionsserver
function push_database {
    echo "⚠️ ACHTUNG: Du willst die lokale Datenbank auf den Produktionsserver übertragen."
    echo "⚠️ Diese Aktion überschreibt die vorhandenen Daten auf dem Produktionsserver!"

    read -p "Bist du sicher, dass du fortfahren möchtest? (j/N) " confirmation
    confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

    if [[ "$confirmation" != "j" && "$confirmation" != "ja" ]]; then
        echo "Aktion abgebrochen."
        return 0
    fi

    echo "Prüfe SSH-Verbindung zu $REMOTE_HOST..."
    if ! ssh -q $REMOTE_HOST exit; then
        echo "Fehler: Keine SSH-Verbindung zu $REMOTE_HOST möglich."
        return 1
    fi

    echo "Erstelle lokalen Datenbank-Dump..."
    ddev export-db --gzip=false > dump.sql
    if ! check_error "Erstellen des lokalen Dumps fehlgeschlagen"; then
        return 1
    fi


    echo "Übertrage Dump zum Produktionsserver..."
    scp dump.sql $REMOTE_HOST:/tmp/dump.sql
    if ! check_error "Übertragen des Dumps fehlgeschlagen"; then
        rm -f dump.sql
        return 1
    fi

    echo "Importiere Dump in die Produktionsdatenbank..."
    ssh $REMOTE_HOST "mysql -h $DB_HOST -u $DB_USER -p'$DB_PASS' $DB_NAME < /tmp/dump.sql && rm -f /tmp/dump.sql"
    if ! check_error "Importieren des Dumps auf dem Produktionsserver fehlgeschlagen"; then
        rm -f dump.sql
        return 1
    fi

    rm -f dump.sql
    echo "Datenbank erfolgreich zum Produktionsserver übertragen."
    return 0
}

# Hauptfunktion mit Menü
function show_menu {
    echo ""
    echo "===== TYPO3-Synchronisierungstool ====="
    echo "1) Datenbank vom Produktionsserver holen"
    echo "2) Fileadmin-Dateien vom Produktionsserver holen"
    echo "======================================"
    echo "3) Datenbank zum Produktionsserver übertragen"
    echo "4) Fileadmin-Dateien zum Produktionsserver übertragen"
    echo "5) Fileadmin-Dateien zum Produktionsserver übertragen (Simulationsmodus)"
    echo "======================================"
    echo "6) Alles vom Produktionsserver downloaden/synchronisieren (DB + Fileadmin)"
    echo "======================================"
    echo "q) Beenden"
    echo "======================================"
    #echo -n "Bitte wählen Sie eine Option: "

    read -r -p "Bitte wählen Sie eine Option: " choice

    case $choice in
        1)
           fetch_database
           ;;
        2)
           fetch_fileadmin
           ;;
        3)
           push_database
           ;;
        4)
           push_fileadmin
           ;;
        5)
           push_fileadmin --dry-run
           ;;
        6)
           echo "Starte vollständige Synchronisierung..."
           fetch_database && fetch_fileadmin
           echo "Vollständige Synchronisierung abgeschlossen."
           ;;
        q)
           exit 0
           ;;
        *)
           echo "Ungültige Option. Bitte erneut versuchen."
           ;;
    esac

    show_menu
}

# Beispiel für config.example.sh erstellen
function create_config_example {
    cat > config.example.sh << EOF
#!/bin/bash
# Konfiguration für TYPO3-Synchronisierungstool
# Kopier diese Datei zu config.sh und passe die Werte an

# SSH-Zugangsdaten
REMOTE_HOST="deinhostname"

# Datenbank-Zugangsdaten
DB_HOST="DATENBANKSERVER"
DB_USER="DATENBANKUSER"
DB_PASS='Ihr-Passwort-Hier'
DB_NAME="DATENBANKNAME"

# Pfade
BASE_PATH="/home/www/PROJEKTNUMMER/html/PROJEKTVERZEICHNIS/production"
SHARED_PATH="\$BASE_PATH/shared"
FILEADMIN_REMOTE="\$SHARED_PATH/public/fileadmin/"
FILEADMIN_LOCAL="public/fileadmin/"
EOF

    echo "Beispiel-Konfigurationsdatei config.example.sh erstellt."
    echo "Bitte kopiere diese Datei zu config.sh und passe die Werte an."
}

# Prüfen auf direkte Kommandozeilenparameter
if [ "$1" = "fetch-db" ]; then
    fetch_database
elif [ "$1" = "fetch-files" ]; then
    fetch_fileadmin
elif [ "$1" = "push-db" ]; then
    push_database
elif [ "$1" = "push-files" ]; then
    push_fileadmin "$2"
elif [ "$1" = "sync-all" ]; then
    fetch_database && fetch_fileadmin
elif [ "$1" = "create-config" ]; then
    create_config_example
else
    # Wenn keine Parameter angegeben wurden, interaktives Menü anzeigen
    show_menu
fi
