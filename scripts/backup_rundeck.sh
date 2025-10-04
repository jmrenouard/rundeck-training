#!/bin/bash

# ==============================================================================
# Script: Sauvegarde de Rundeck
# Description: Ce script arrête Rundeck, sauvegarde la base de données et les
#              fichiers importants, puis redémarre Rundeck.
# ==============================================================================

set -e
set -o pipefail

# --- Couleurs et Fonctions ---
C_RESET='\033[0m'; C_RED='\033[0;31m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'; C_BLUE='\033[0;34m'
info() { echo -e    "${C_BLUE}[INFO   ]${C_RESET}ℹ️ $1"; }
success() { echo -e "${C_GREEN}[SUCCESS]${C_RESET}✅ $1"; }
warn() { echo -e    "${C_YELLOW}[WARN   ]${C_RESET}⚠️ $1"; }
error() { echo -e   "${C_RED}[ERROR  ]${C_RESET}❌ $1" >&2; echo ".... Fin du script avec une erreur"; exit 1; }
start_script() { echo -e "${C_BLUE}[START  ]${C_RESET}🏁 $1🚀"; }
end_success() { echo -e "${C_GREEN}[END    ]${C_RESET}🏁 $1"; exit 0; }

# --- Variables de Configuration (doivent correspondre à install_mysql.sh) ---
DB_NAME="rundeck"
DB_USER="rundeckuser"
DB_PASS="rundeckpassword"

# --- Répertoire de Sauvegarde ---
BACKUP_DIR="/var/backups/rundeck"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/rundeck_backup_$TIMESTAMP.tar.gz"
DB_BACKUP_FILE="/tmp/rundeck_db_$TIMESTAMP.sql"

# --- Répertoires à sauvegarder ---
RUNDECK_LOGS_DIR="/var/lib/rundeck/logs"
RUNDECK_KEYSTORE_DIR="/var/lib/rundeck/keystore"
RUNDECK_PROJECTS_DIR="/var/lib/rundeck/projects"
RUNDECK_CONFIG_DIR="/etc/rundeck"

# --- Début du script ---
start_script "### Sauvegarde de Rundeck ###"

# --- Vérification des droits root ---
if [ "$(id -u)" -ne 0 ]; then
    error "Ce script doit être exécuté en tant que root. Utilisez 'sudo'."
fi

# --- Création du répertoire de sauvegarde ---
info "Création du répertoire de sauvegarde s'il n'existe pas..."
mkdir -p "$BACKUP_DIR"
success "Répertoire de sauvegarde prêt : $BACKUP_DIR"

# --- Arrêt du service Rundeck ---
info "Arrêt du service Rundeck pour garantir la cohérence des données..."
if systemctl is-active --quiet rundeckd; then
    systemctl stop rundeckd || error "Échec de l'arrêt du service Rundeck."
    success "Service Rundeck arrêté."
else
    warn "Le service Rundeck n'était pas en cours d'exécution."
fi

# --- Sauvegarde de la base de données ---
info "Sauvegarde de la base de données MySQL '$DB_NAME'..."
# Créer un fichier temporaire pour les identifiants MySQL
MYSQL_CNF=$(mktemp)
chmod 600 "$MYSQL_CNF"
cat > "$MYSQL_CNF" <<EOF
[client]
user=$DB_USER
password=$DB_PASS
host=localhost
EOF

mysqldump --defaults-extra-file="$MYSQL_CNF" "$DB_NAME" > "$DB_BACKUP_FILE" || {
    rm -f "$MYSQL_CNF"
    error "La sauvegarde de la base de données a échoué."
    # Redémarrer Rundeck même en cas d'échec
    info "Tentative de redémarrage du service Rundeck..."
    systemctl start rundeckd
    exit 1
}
rm -f "$MYSQL_CNF"
success "Base de données sauvegardée dans '$DB_BACKUP_FILE'."

# --- Sauvegarde des fichiers ---
info "Création de l'archive des fichiers de Rundeck..."
# La commande tar ci-dessous utilise plusieurs options '-C' pour inclure des fichiers et dossiers de différents emplacements.
# Structure de l'archive résultante :
# - $(basename "$DB_BACKUP_FILE") (fichier de sauvegarde de la base de données, à la racine de l'archive)
# - logs/ (dossier de logs Rundeck)
# - keystore/ (dossier keystore Rundeck)
# - projects/ (dossier projets Rundeck)
# - rundeck/ (dossier de configuration /etc/rundeck)
#
# La restauration se fait en extrayant l'archive dans un répertoire temporaire,
# puis en utilisant 'rsync' pour fusionner les répertoires sauvegardés avec
# les répertoires de destination. Cette méthode préserve les fichiers existants
# qui ne sont pas dans la sauvegarde.
tar -czf "$BACKUP_FILE" \
    -C /tmp "$(basename "$DB_BACKUP_FILE")" \
    -C "$(dirname "$RUNDECK_LOGS_DIR")" "$(basename "$RUNDECK_LOGS_DIR")" \
    -C "$(dirname "$RUNDECK_KEYSTORE_DIR")" "$(basename "$RUNDECK_KEYSTORE_DIR")" \
    -C "$(dirname "$RUNDECK_PROJECTS_DIR")" "$(basename "$RUNDECK_PROJECTS_DIR")" \
    -C /etc "rundeck" || {
    error "La création de l'archive de sauvegarde a échoué."
    # Redémarrer Rundeck même en cas d'échec
    info "Tentative de redémarrage du service Rundeck..."
    systemctl start rundeckd
    exit 1
}
success "Archive de sauvegarde créée : $BACKUP_FILE"

# --- Vérification de l'intégrité de l'archive ---
info "Vérification de l'intégrité de l'archive de sauvegarde..."
if tar -tzf "$BACKUP_FILE" > /dev/null 2>&1; then
    success "L'intégrité de l'archive est confirmée."
    # --- Nettoyage ---
    info "Nettoyage du fichier de sauvegarde temporaire de la base de données..."
    rm -f "$DB_BACKUP_FILE"
    success "Fichier temporaire supprimé."
else
    error "L'archive de sauvegarde est corrompue. Le fichier temporaire n'a pas été supprimé."
    # Optionally, handle the error (e.g., exit, alert, etc.)
    exit 1
fi

# --- Redémarrage du service Rundeck ---
info "Redémarrage du service Rundeck..."
systemctl start rundeckd || error "Le redémarrage du service Rundeck a échoué."
success "Service Rundeck redémarré avec succès."

end_success "Sauvegarde de Rundeck terminée avec succès."