#!/bin/bash

# ==============================================================================
# Script: Installation de Rundeck Enterprise (PagerDuty Process Automation)
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

# --- Variables de Configuration ---
DB_NAME="rundeck"
DB_USER="rundeckuser"
DB_PASS="rundeckpassword"
RUNDECK_PORT="4440"
# Récupération de l'adresse IP de la machine. Pour un vrai cluster, remplacez par l'IP du Load Balancer.
SERVER_IP=$(hostname -I | awk '{print $1}')
LOAD_BALANCER_URL="http://$SERVER_IP:$RUNDECK_PORT"

# --- Fichiers de Configuration ---
RUNDECK_CONFIG="/etc/rundeck/rundeck-config.properties"
RUNDECK_PROFILE="/etc/rundeck/profile"
RUNDECK_LICENSE="/etc/rundeck/rundeckpro-license.key"

# --- Début du script ---
start_script "### Étape 3 : Installation et Configuration de Rundeck Enterprise ###"

# --- Tests Prérequis ---
info "Vérification des prérequis..."
if ! command -v java &>/dev/null; then
    error "Java n'est pas installé. Veuillez d'abord exécuter le script d'installation de Java."
fi
if ! command -v mysql &>/dev/null; then
    error "MySQL n'est pas installé. Veuillez d'abord exécuter le script d'installation de MySQL."
fi
if [ ! -f "$RUNDECK_LICENSE" ]; then
    error "Fichier de licence non trouvé à l'emplacement '$RUNDECK_LICENSE'. Veuillez l'installer avant de lancer ce script."
fi
if [ -f "/etc/rundeck/rundeck-config.properties" ]; then
    warn "Rundeck Enterprise semble déjà installé. Le script vérifiera la configuration."
fi
success "Prérequis validés."

# --- Installation ---
info "Configuration du référentiel Rundeck Enterprise..."
# (La clé et l'URL exactes sont fournies par PagerDuty/Rundeck lors de l'achat)
echo "deb https://rundeckpro.bintray.com/deb stable main" | tee /etc/apt/sources.list.d/rundeck.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 379CE192D401AB61 &>/dev/null || error "L'ajout de la clé du référentiel a échoué."
success "Référentiel Rundeck Enterprise ajouté."

info "Mise à jour de la liste des paquets..."
apt-get update &>/dev/null || error "La mise à jour de la liste des paquets a échoué."
success "Le cache APT a été mis à jour."

info "Installation de Rundeck Enterprise Cluster..."
apt-get install -y rundeckpro-cluster &>/dev/null || error "L'installation de Rundeck Enterprise a échoué."
success "Rundeck Enterprise a été installé avec succès."

# --- Configuration ---
info "Configuration de Rundeck pour utiliser MySQL et le mode Cluster..."
if [ ! -f "$RUNDECK_CONFIG" ]; then
    error "Le fichier de configuration de Rundeck '$RUNDECK_CONFIG' n'a pas été trouvé."
fi

# Sauvegarde du fichier de configuration original
cp "$RUNDECK_CONFIG" "$RUNDECK_CONFIG.bak"

# Modification du fichier de configuration
sed -i "s|grails.server.url=.*|grails.serverURL=$LOAD_BALANCER_URL|" "$RUNDECK_CONFIG"
sed -i "s|dataSource.dbCreate =.*|dataSource.dbCreate = update|" "$RUNDECK_CONFIG"
sed -i "s|dataSource.url =.*|dataSource.url = jdbc:mysql://localhost/$DB_NAME?autoReconnect=true&useSSL=false|" "$RUNDECK_CONFIG"
sed -i "s|dataSource.username =.*|dataSource.username = $DB_USER|" "$RUNDECK_CONFIG"
sed -i "s|dataSource.password =.*|dataSource.password = $DB_PASS|" "$RUNDECK_CONFIG"
# Ajout du driver si absent
if ! grep -q "dataSource.driverClassName" "$RUNDECK_CONFIG"; then
    echo "dataSource.driverClassName = com.mysql.cj.jdbc.Driver" >> "$RUNDECK_CONFIG"
fi

# Activation du mode Cluster
if ! grep -q "rundeck.clusterMode.enabled" "$RUNDECK_CONFIG"; then
    echo "" >> "$RUNDECK_CONFIG"
    echo "# --- Configuration du mode Cluster ---" >> "$RUNDECK_CONFIG"
    echo "rundeck.clusterMode.enabled = true" >> "$RUNDECK_CONFIG"
    echo "rundeck.clusterMode.autotakeover.enabled = true" >> "$RUNDECK_CONFIG"
    echo "rundeck.clusterMode.autotakeover.policy = any" >> "$RUNDECK_CONFIG"
fi
success "La configuration de la base de données et du mode cluster dans '$RUNDECK_CONFIG' a été mise à jour."

info "Configuration du port et de l'adresse de Rundeck dans le profil..."
if [ ! -f "$RUNDECK_PROFILE" ]; then
    error "Le fichier de profil de Rundeck '$RUNDECK_PROFILE' n'a pas été trouvé."
fi

# Sauvegarde du fichier de profil original
cp "$RUNDECK_PROFILE" "$RUNDECK_PROFILE.bak"

sed -i 's/export RDECK_JVM_SETTINGS="-Xmx1024m -Xms256m -server"/export RDECK_JVM_SETTINGS="-Xmx4096m -Xms1024m -server"/' "$RUNDECK_PROFILE"
sed -i "s|-Drundeck.server.http.port=4440|-Drundeck.server.http.port=$RUNDECK_PORT|" "$RUNDECK_PROFILE"
# Assurer que l'adresse d'écoute est 0.0.0.0 pour être accessible de l'extérieur
if ! grep -q "rundeck.server.address" "$RUNDECK_PROFILE"; then
    echo "export RDECK_SERVER_CONFIG="\$RDECK_SERVER_CONFIG -Drundeck.server.address=0.0.0.0"" >> "$RUNDECK_PROFILE"
fi
success "Le profil de Rundeck a été mis à jour."

# --- Démarrage et Activation du Service ---
info "Démarrage et activation du service Rundeck..."
systemctl daemon-reload
systemctl enable rundeckd
systemctl restart rundeckd || error "Le redémarrage du service Rundeck a échoué. Consultez les logs avec 'journalctl -u rundeckd'."
success "Le service Rundeck a été démarré et activé."

# --- Pause pour démarrage ---
warn "Rundeck peut prendre plusieurs minutes pour démarrer la première fois. Pause de 120 secondes..."
sleep 120s

# --- Tests Post-Installation ---
info "Validation de l'installation de Rundeck Enterprise..."
if ! systemctl is-active --quiet rundeckd; then
    error "Le service Rundeck n'a pas pu démarrer. Consultez les logs : 'journalctl -u rundeckd'."
fi
if ! ss -tuln | grep -q ":$RUNDECK_PORT"; then
    error "Rundeck n'écoute pas sur le port $RUNDECK_PORT."
fi
MAX_RETRIES=12
RETRY_DELAY=10
RETRY_COUNT=0
while true; do
    if curl -s -I "$LOAD_BALANCER_URL/user/login" | grep -q "HTTP/1.1 200 OK"; then
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        error "La réponse de Rundeck sur $LOAD_BALANCER_URL est inattendue après $MAX_RETRIES tentatives. Le service est peut-être encore en cours de démarrage ou rencontre un problème."
    fi
    sleep $RETRY_DELAY
done
success "Rundeck Enterprise est actif et répond correctement sur $LOAD_BALANCER_URL (login: admin, pass: admin)."

end_success "Installation et configuration de Rundeck Enterprise terminées avec succès."
