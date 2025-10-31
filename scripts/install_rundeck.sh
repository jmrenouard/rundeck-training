#!/bin/bash

# ==============================================================================
# Script: Installation de Rundeck
# ==============================================================================

set -e
set -o pipefail

# --- Couleurs et Fonctions ---
C_RESET='\033[0m'; C_RED='\033[0;31m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_BLUE='\033[0;34m'
info() { echo -e    "${C_BLUE}[INFO   ]${C_RESET}ℹ️ $1"; }
success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET}✅ $1"; }
warn() { echo -e    "${C_YELLOW}[WARN   ]${C_RESET}⚠️ $1"; }
error() { echo -e   "${C_RED}[ERROR  ]${C_RESET}❌ $1" >&2; echo ".... Fin le script avec une erreur"; exit 1; }
start_script() { echo -e "${C_BLUE}[START  ]${C_RESET}🏁 $1🚀"; }
end_success() { echo -e "${C_GREEN}[END    ]${C_RESET}🏁 $1"; exit 0; }

# --- Variables de Configuration (doivent correspondre à install_mysql.sh) ---
DB_NAME="rundeck"
DB_USER="rundeckuser"
DB_PASS="rundeckpassword"
RUNDECK_PORT=${2:-"4440"}
# Récupération de l'adresse IP de la machine pour la configuration de Rundeck
#SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_IP=${1:-"rundeck.srv.lightpath.fr"}

# --- Fichiers de Configuration ---
RUNDECK_CONFIG="/etc/rundeck/rundeck-config.properties"
RUNDECK_PROFILE="/etc/rundeck/profile"

# --- Début du script ---
start_script "### Étape 3 : Installation et Configuration de Rundeck ###"

# --- Tests Prérequis ---
info "Vérification des prérequis..."
if ! command -v java &>/dev/null; then
    error "Java n'est pas installé. Veuillez d'abord exécuter le script d'installation de Java."
fi
if ! command -v mysql &>/dev/null; then
    error "MySQL n'est pas installé. Veuillez d'abord exécuter le script d'installation de MySQL."
fi
if [ -f "/etc/rundeck/rundeck-config.properties" ]; then
    warn "Rundeck semble déjà installé. Le script vérifiera la configuration."
fi
success "Prérequis validés."

# --- Installation ---
info "Configuration du référentiel Rundeck..."
    curl -fsSL https://packages.rundeck.com/pagerduty/rundeck/gpgkey | tee /etc/apt/trusted.gpg.d/rundeck-key.asc >/dev/null || error "Échec du téléchargement de la clé GPG de Rundeck."
    echo "deb https://packages.rundeck.com/pagerduty/rundeck/any/ any main" | tee /etc/apt/sources.list.d/rundeck.list >/dev/null || error "Échec de l'écriture du fichier sources.list de Rundeck."
    echo "deb-src https://packages.rundeck.com/pagerduty/rundeck/any/ any main" | tee -a /etc/apt/sources.list.d/rundeck.list >/dev/null || error "Échec de l'écriture du fichier sources.list de Rundeck." &>/dev/null || error "L'ajout du référentiel Rundeck a échoué."
success "Référentiel Rundeck ajouté."

info "Mise à jour de la liste des paquets..."
apt-get update || error "La mise à jour de la liste des paquets a échoué."
success "Le cache APT a été mis à jour."

info "Installation de Rundeck..."
apt-get install -y rundeck || error "L'installation de Rundeck a échoué."
success "Rundeck a été installé with succès."

info "Téléchargement du driver JDBC MySQL..."
mkdir -p /var/lib/rundeck/lib
curl -L -o /var/lib/rundeck/lib/mysql-connector-java-8.0.28.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.28/mysql-connector-java-8.0.28.jar || error "Le téléchargement du driver JDBC a échoué."
chown rundeck:rundeck /var/lib/rundeck/lib/mysql-connector-java-8.0.28.jar
success "Driver JDBC MySQL téléchargé."


# --- Configuration ---
info "Génération du fichier de configuration Rundeck..."
tee "$RUNDECK_CONFIG" > /dev/null <<EOF
#loglevel.default is the default log level for jobs: ERROR,WARN,INFO,VERBOSE,DEBUG
loglevel.default=INFO
rdeck.base=/var/lib/rundeck
rss.enabled=false

# change hostname here
grails.serverURL=http://$SERVER_IP:$RUNDECK_PORT

# dataSource configuration
dataSource.dbCreate = update
dataSource.url = jdbc:mysql://localhost/$DB_NAME?autoReconnect=true&useSSL=false
dataSource.username = $DB_USER
dataSource.password = $DB_PASS
dataSource.driverClassName = com.mysql.cj.jdbc.Driver
dataSource.dialect = org.hibernate.dialect.MySQL8Dialect
grails.plugin.databasemigration.updateOnStart=true

# Encryption for key storage
rundeck.storage.provider.1.type=db
rundeck.storage.provider.1.path=keys
rundeck.storage.converter.1.type=jasypt-encryption
rundeck.storage.converter.1.path=keys
rundeck.storage.converter.1.config.encryptorType=custom
rundeck.storage.converter.1.config.password=changeme
rundeck.storage.converter.1.config.algorithm=PBEWITHSHA256AND128BITAES-CBC-BC
rundeck.storage.converter.1.config.provider=BC

# Encryption for project config storage
rundeck.projectsStorageType=db
rundeck.config.storage.converter.1.type=jasypt-encryption
rundeck.config.storage.converter.1.path=projects
rundeck.config.storage.converter.1.config.password=changeme
rundeck.config.storage.converter.1.config.encryptorType=custom
rundeck.config.storage.converter.1.config.algorithm=PBEWITHSHA256AND128BITAES-CBC-BC
rundeck.config.storage.converter.1.config.provider=BC

rundeck.feature.repository.enabled=true
server.useForwardHeaders = true

# Autoriser l'URL spécifique dans form-action
rundeck.security.httpHeaders.provider.csp.config.form-action='self' https://$SERVER_IP

EOF
success "Le fichier de configuration Rundeck a été généré."

info "Configuration du port et de l'adresse de Rundeck dans le profil..."
if [ ! -f "$RUNDECK_PROFILE" ]; then
    error "Le fichier de profil de Rundeck '$RUNDECK_PROFILE' n'a pas été trouvé."
fi

# Sauvegarde du fichier de profil original
cp "$RUNDECK_PROFILE" "$RUNDECK_PROFILE.bak"

sed -i 's/export RDECK_JVM_SETTINGS="-Xmx1024m -Xms256m -server"/export RDECK_JVM_SETTINGS="-Xmx2048m -Xms512m -server"/' "$RUNDECK_PROFILE"
sed -i "s|-Drundeck.server.http.port=4440|-Drundeck.server.http.port=$RUNDECK_PORT|" "$RUNDECK_PROFILE"
# Assurer que l'adresse d'écoute est 0.0.0.0 pour être accessible de l'extérieur
if ! grep -q "rundeck.server.address" "$RUNDECK_PROFILE"; then
    echo "export RDECK_SERVER_CONFIG=\"$RDECK_SERVER_CONFIG -Drundeck.server.address=0.0.0.0\"" >> "$RUNDECK_PROFILE"
fi

# Add forwarded option for reverse proxy
if ! grep -q "rundeck.jetty.connector.forwarded" "$RUNDECK_PROFILE"; then
    sed -i '/^export RDECK_JVM/ s/"$/ -Drundeck.jetty.connector.forwarded=true"/' "$RUNDECK_PROFILE"
fi
success "Le profil de Rundeck a été mis à jour."

# --- Démarrage et Activation du Service ---
info "Démarrage et activation du service Rundeck..."
systemctl daemon-reload
systemctl enable rundeckd
systemctl restart rundeckd || error "Le redémarrage du service Rundeck a échoué. Consultez les logs avec 'journalctl -u rundeckd'."
success "Le service Rundeck a été démarré et activé."

# --- Pause pour démarrage ---
warn "Rundeck peut prendre plusieurs minutes pour démarrer la première fois. Pause de 5 secondes..."
sleep 5s

# --- Tests Post-Installation ---
info "Validation de l'installation de Rundeck..."
if ! systemctl is-active --quiet rundeckd; then
    error "Le service Rundeck n'a pas pu démarrer. Consultez les logs : 'journalctl -u rundeckd'."
fi
if ! ss -tuln | grep -q ":$RUNDECK_PORT"; then
    error "Rundeck n'écoute pas sur le port $RUNDECK_PORT."
fi
MAX_RETRIES=10
RETRY_DELAY=5
RETRY_COUNT=0
while true; do
    if curl -s -I "http://localhost:$RUNDECK_PORT/user/login" | grep -q "HTTP/1.1 200 OK"; then
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        error "La réponse de Rundeck sur localhost:$RUNDECK_PORT est inattendue après $MAX_RETRIES tentatives. Le service est peut-être encore en cours de démarrage ou rencontre un problème."
    fi
    sleep $RETRY_DELAY
done
success "Rundeck est actif et répond correctement sur http://$SERVER_IP:$RUNDECK_PORT (login: admin, pass: admin)."

end_success "Installation et configuration de Rundeck terminées avec succès."