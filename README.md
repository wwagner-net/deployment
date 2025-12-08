## Weiterer im Webinar gezeigter Code

https://notes.typo3.org/LPIySjxXSCGKPI_twS6r6w

## Notes

### **SSH Schlüssel und Verbindungsmanagement**
- Das Aufsetzen von **drei SSH-Schlüsselpaaren** ist grundlegend für ein automatisiertes Deployment und sichere Verbindungen.
- **Drei Schlüsselpaar-Typen** sind erforderlich: für die Verbindung lokal zum Server, von GitHub zum Server für das Deployment und für den GitHub Account selbst, um passwortlos Git Push/Pull zu ermöglichen.
    - Wolfgang empfiehlt, für jedes Gerät und jedes Projekt eigene Schlüsselpaare zu erzeugen, um Sicherheit und Übersicht zu erhöhen.
    - Die Schlüsselpaare nutzen moderne Algorithmen wie **ED25519** für bessere Performance und Sicherheit gegenüber älteren RSA-Schlüsseln.
    - Private Schlüssel bleiben lokal und dürfen nie geteilt werden, öffentliche Schlüssel werden auf Servern und in GitHub hinterlegt.
- Die **SSH-Konfigurationsdatei (config)** lokal erleichtert das Verbindungsmanagement durch Aliasnamen, die IP-Adressen, Benutzernamen, Ports und Pfade zum privaten Schlüssel enthalten.
    - Wolfgang hebt hervor, dass bei einigen Hostern ein Keep-Alive-Mechanismus in der Konfigurationsdatei nötig ist, um Verbindungsabbrüche zu vermeiden.
- Auf dem Server wird der öffentliche Schlüssel in der Datei **authorized_keys** hinterlegt, wobei der Vim-Editor empfohlen wird, um unerwünschte Zeilenumbrüche zu vermeiden.
- Wolfgang betont, dass SSH-Zugang heute ein Muss ist und FTP für Deployment nicht mehr zeitgemäß ist; bei Hostern ohne SSH-Zugang empfiehlt er einen Wechsel.
- Für die Verbindung von GitHub Actions zum Server wird der private Schlüssel als **GitHub Secret** hinterlegt, der öffentliche Schlüssel auf dem Server, um automatisiertes Deployment zu ermöglichen (00:57, 02:32).
### **Git & Repository Setup**
- Ein sauberer Git-Workflow mit korrektem Repository-Setup ist die Basis für automatisiertes Deployment.
- Wolfgang zeigt, wie man ein **lokales Git Repository initialisiert** (git init, git add, git commit) und mit einem Remote-Repository auf GitHub verbindet (git remote add origin).
    - Der Standard-Branch heißt heute **main**; falls der lokale Branch anders heißt (z.B. master), empfiehlt Wolfgang eine Umbenennung aus Kompatibilitätsgründen.
- Die **.gitignore-Datei** wird vor der Initialisierung angelegt, um unnötige oder sensible Dateien und Ordner (z.B. var, vendor, .DS_Store, etc.) vom Repository auszuschließen.
    - Wolfgang weist darauf hin, dass die Reihenfolge in der .gitignore wichtig ist, um Ausnahmen korrekt zu definieren.
    - Er warnt vor Ausschlüssen wie `*.sql`, da viele Extensions SQL-Dateien benötigen und durch zu frühes Ausschließen Fehler entstehen können.
- GitHub Organisationen werden empfohlen, um Projekte gemeinschaftlich zu verwalten, besonders bei Teams oder Agenturen.
- Erste Git Pushes werden mit `git push -u origin main` ausgeführt, um den lokalen Branch mit dem Remote-Branch zu verknüpfen.
- Wolfgang empfiehlt, bei Problemen mit Git Push Fehlern wie "ref spec main does not match" den Branch-Namen zu prüfen und ggf. anzupassen.
### **Deployment mit GitHub Actions und Deployer**
- Das Deployment wird vollständig automatisiert über eine Kombination aus **GitHub Actions**, einem Docker-Container und dem PHP-Tool **Deployer** realisiert.
- Ein GitHub Workflow wird über eine YAML-Datei im Ordner `.github/workflows/deploy.yaml` definiert, die beim Push in den Branch **main** das Deployment startet.
    - Der Workflow läuft in einem Ubuntu-Docker-Container, der PHP 8.4 inklusive notwendiger Extensions (mbstring, intl) und Composer enthält.
    - Deployer wird per Composer global installiert und anschließend über einen Terminalbefehl (`dep deploy production -vvv`) das Deployment ausgeführt.
- Für die SSH-Verbindung des Workflows zum Server wird ein **SSH-Agent** eingesetzt, der den privaten Schlüssel aus GitHub Secrets nutzt.
    - Zusätzlich wird die Datei `.known_hosts` im Container mit dem öffentlichen Schlüssel des Servers via `ssh-keyscan` gepflegt, um die Verbindung zu erlauben.
- Das Deployment nutzt Composer, um im Container die Abhängigkeiten zu installieren, wobei nur Production-Pakete (no-dev) installiert werden und die Plattform-Anforderungen ignoriert werden, um Fehler zu vermeiden.
- Deployer synchronisiert Dateien per **rsync**, welches nur geänderte Dateien überträgt, was die Uploadzeit erheblich verkürzt.
- Die Host- und Deployer-Konfigurationsdateien definieren Server-IP, SSH-Port, Benutzername, Pfade, Shared Folders (z.B. FileAdmin, Typo Temp) und Dateirechte, um auf dem Server die korrekte Struktur und Rechte zu gewährleisten (01:54, 02:02).
- Shared Ordner verhindern redundantes Speichern großer Ordner (z.B. FileAdmin) über mehrere Releases und ermöglichen einfache Rollbacks.
- Der Deployment-Prozess umfasst Tasks wie Datenbank-Backup, Cache-Warmup, Extension Setup und Datenbank-Updates, die in einer definierten Reihenfolge ausgeführt werden, um Stabilität zu gewährleisten (02:20, 02:28).
- Wolfgang demonstriert, wie ein Deployment-Run live in GitHub Actions abläuft und wie man Fehlerquellen anhand der Log-Ausgabe schnell identifizieren kann, z.B. bei falschen Datenbank-Zugangsdaten (03:00, 03:04).
- Rollbacks können manuell durch das Umschalten des Symlinks `current` auf ein vorheriges Release durchgeführt werden, was schnell und zuverlässig die vorherige Version wiederherstellt.
- Deployer bietet auch einen Rollback-Befehl, der aber in Wolfgangs Setup nicht genutzt wird, da er Deployer nicht lokal installiert, um die Unterscheidung von Dev- und Prod-Umgebungen zu wahren.
### **Synchronisations- und Hilfsskripte**
- Zusätzliche Shell-Skripte erleichtern die Synchronisation von Datenbank und Dateien zwischen lokalem Entwicklungsprojekt und Live-Server.
- Das **sync.sh** Skript bietet ein Menü zum einfachen Importieren und Exportieren von Datenbank-Dumps und FileAdmin-Ordnern zwischen lokalem Projekt und Server.
    - Es erlaubt Datenbank-Backups vom Server lokal zu holen, sowie lokale Datenbank und Dateien auf den Server hochzuladen.
    - Das Skript nutzt SSH und rsync, um Transfers effizient und sicher durchzuführen.
- Wolfgang weist auf mögliche Probleme mit rsync-Versionen auf Servern hin, die zu Hängern führen können, empfiehlt aber im Fehlerfall Neustart des Skripts.
- Die Konfigurationsdatei **config.sh** speichert zentrale Parameter wie Server-IP, Datenbank-Zugangsdaten und Pfade, um das Skript flexibel einsetzbar zu machen.
- Die Skripte werden lokal ausgeführt, um Entwicklungsdaten mit dem Live-Server abzugleichen, was den Workflow in Teams mit mehreren Redakteuren unterstützt.
### **Branching, Staging und Testing Strategien**
- Ein mehrstufiger Workflow mit separaten Branches und Deployments für Staging und Production wird empfohlen, um Qualität und Kontrolle zu erhöhen.
- Es werden mindestens zwei Branches genutzt: **main** für die stabile Live-Version und **staging** für Entwicklungs- und Testzwecke.
- Der GitHub Workflow wird so konfiguriert, dass Pushes in den jeweiligen Branch unterschiedliche Deployments auf separate Verzeichnisse oder Server triggern.
- Optional wird ein gemeinsamer Shared Folder genutzt, was jedoch Risiken birgt, wenn Staging- und Live-Instanzen denselben FileAdmin-Ordner verwenden.
- Frontend-Tests werden mit Tools wie **Playwright** (bevorzugt von Wolfgang) oder Cypress in die Pipeline eingebaut, um automatisierte UI-Checks vor dem Live-Deployment zu ermöglichen.
    - Tests prüfen z.B. das Vorhandensein wichtiger Texte, Login-Formulare oder Seiten, um Fehler früh zu erkennen.
    - Für Playwright wird eine separate Testumgebung mit Passwortschutz empfohlen, um automatisierte Tests gegen reale Inhalte auszuführen.
- Das Deployment läuft in Stufen: Zuerst Deployment auf Staging, dann automatisierte Tests, bei Erfolg folgt das Live-Deployment.
- Wolfgang weist darauf hin, dass Playwright-Tests individuell an das Projekt angepasst werden müssen, es keine festen Standardtests für Typo gibt.
- Die Kombination von Staging mit automatisierten Frontend-Tests erhöht die Zuverlässigkeit und ermöglicht vollständige Automatisierung von Updates.
### **Automatisierte Updates und Wartung mit Renovate**
- Renovate wird als Tool genutzt, um **Composer- und andere Paketupdates** automatisch zu überwachen und zu integrieren, was die Wartung stark vereinfacht.
- Renovate prüft Repository-Pakete auf Updates und erstellt automatisch Pull Requests mit Versionsänderungen.
- Updates können auf Patch- und Minor-Versionen beschränkt werden, Major-Upgrades können ausgeschlossen werden, um Stabilität zu gewährleisten.
- Nach Review und Merge eines PRs läuft das Deployment automatisch, wodurch die Projekte stets aktuell gehalten werden.
- Kombination mit Playwright-Tests ermöglicht ein komplett automatisiertes Update-Verfahren mit Testabsicherung vor Live-Schaltung.
- Renovate erlaubt die Konfiguration von Arbeitszeiten für Updates und individuelle Ausschlüsse von lokalen Paketen.
- Wolfgang empfiehlt, Updates der Extensions je nach Risiko manuell zu steuern, während Core-Updates oft automatisiert laufen.
- Die Einführung von Renovate hat den Zeitaufwand für Updates in der Agentur deutlich reduziert, von manuellem Aufwand auf wenige Klicks.
