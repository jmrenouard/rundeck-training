#!/bin/bash

# ==============================================================================
# Script: Restauration de Rundeck
# Description: Ce script arrête Rundeck, restaure la base de données et les
#              fichiers à partir d'une sauvegarde, puis redémarre Rundeck.
# Utilisation: sudo ./restore_rundeck.sh /chemin/vers/votre/backup.tar.gz
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

# --- Fichier de Sauvegarde ---
if [ "$#" -ne 1 ]; then
    error "Utilisation : $0 /chemin/vers/le/fichier_de_backup.tar.gz"
fi
BACKUP_FILE="$1"

# --- Variables de Configuration (doivent correspondre à install_mysql.sh) ---
DB_NAME="${RUNDECK_DB_NAME}"
DB_USER="${RUNDECK_DB_USER}"
DB_PASS="${RUNDECK_DB_PASS}"

# Vérification que les variables d'environnement sont définies
if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASS" ]; then
    error "Les variables d'environnement RUNDECK_DB_NAME, RUNDECK_DB_USER et RUNDECK_DB_PASS doivent être définies."
fi
# --- Répertoire Temporaire pour l'Extraction ---
EXTRACT_DIR="/tmp/rundeck_restore_$$"

# --- Début du script ---
start_script "### Restauration de Rundeck ###"

# --- Vérification des droits root ---
if [ "$(id -u)" -ne 0 ]; then
    error "Ce script doit être exécuté en tant que root. Utilisez 'sudo'."
fi

# --- Validation du fichier de sauvegarde ---
if [ ! -f "$BACKUP_FILE" ]; then
    error "Le fichier de sauvegarde '$BACKUP_FILE' n'a pas été trouvé."
fi
info "Utilisation du fichier de sauvegarde : $BACKUP_FILE"

# --- Arrêt du service Rundeck ---
info "Arrêt du service Rundeck..."
if systemctl is-active --quiet rundeckd; then
    systemctl stop rundeckd || error "Échec de l'arrêt du service Rundeck."
    success "Service Rundeck arrêté."
else
    warn "Le service Rundeck n'était pas en cours d'exécution."
fi

# --- Création du répertoire d'extraction et extraction ---
info "Création du répertoire temporaire et extraction de l'archive..."
mkdir -p "$EXTRACT_DIR"
tar -xzf "$BACKUP_FILE" -C "$EXTRACT_DIR" || {
    error "L'extraction de l'archive a échoué."
    rm -rf "$EXTRACT_DIR"
    # Redémarrer Rundeck même en cas d'échec
    info "Tentative de redémarrage du service Rundeck..."
    systemctl start rundeckd
    exit 1
}
# --- Vérification du fichier de sauvegarde SQL ---
info "Vérification du fichier de sauvegarde SQL dans l'archive..."
SQL_FILES=$(find "$EXTRACT_DIR" -name "*.sql" -type f)
NUM_SQL_FILES=$(echo "$SQL_FILES" | wc -w)

if [ "$NUM_SQL_FILES" -eq 0 ]; then
    error "Aucun fichier de sauvegarde SQL (*.sql) n'a été trouvé dans l'archive."
    rm -rf "$EXTRACT_DIR"
    info "Tentative de redémarrage du service Rundeck..."
    systemctl start rundeckd
    exit 1
elif [ "$NUM_SQL_FILES" -gt 1 ]; then
    error "Plusieurs fichiers de sauvegarde SQL ont été trouvés dans l'archive. Restauration annulée."
    warn "Fichiers trouvés :"
    echo "$SQL_FILES"
    rm -rf "$EXTRACT_DIR"
    info "Tentative de redémarrage du service Rundeck..."
    systemctl start rundeckd
    exit 1
fi

DB_BACKUP_FILE="$SQL_FILES"
success "Fichier de sauvegarde SQL unique trouvé : $DB_BACKUP_FILE"

# --- Restauration de la base de données ---
info "Restauration de la base de données MySQL '$DB_NAME'..."
# Créer un fichier temporaire pour les identifiants MySQL
MYSQL_CNF=$(mktemp)
chmod 600 "$MYSQL_CNF"
cat > "$MYSQL_CNF" <<EOF
[client]
user=$DB_USER
password=$DB_PASS
database=$DB_NAME
EOF

mysql --defaults-extra-file="$MYSQL_CNF" "$DB_NAME" < "$DB_BACKUP_FILE" || {
    error "La restauration de la base de données a échoué."
    rm -rf "$EXTRACT_DIR"
    rm -f "$MYSQL_CNF"
    info "Tentative de redémarrage du service Rundeck..."
    systemctl start rundeckd
    exit 1
}
rm -f "$MYSQL_CNF"
success "Base de données restaurée avec succès."

# --- Restauration des fichiers ---
# Vérification de la présence des répertoires requis dans la sauvegarde extraite
REQUIRED_DIRS=("logs" "keystore" "projects" "rundeck")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$EXTRACT_DIR/$dir" ]; then
        error "Le répertoire requis '$dir' est manquant dans la sauvegarde extraite."
        rm -rf "$EXTRACT_DIR"
        info "Tentative de redémarrage du service Rundeck..."
        systemctl start rundeckd
        exit 1
    fi
done
info "Tous les répertoires requis sont présents dans la sauvegarde extraite."
info "Restauration des fichiers de Rundeck..."
warn "Cette opération fusionne les fichiers de la sauvegarde avec les fichiers existants."
warn "Les fichiers de la sauvegarde écraseront les fichiers existants en cas de conflit."
warn "Aucun fichier existant non présent dans la sauvegarde ne sera supprimé."

# Utilisation de rsync pour une restauration plus sûre qui ne supprime pas de fichiers inattendus.
info "Restauration des répertoires de données..."
rsync -a "$EXTRACT_DIR/logs/" /var/lib/rundeck/logs/ || error "Échec de la restauration du répertoire 'logs'."
rsync -a "$EXTRACT_DIR/keystore/" /var/lib/rundeck/keystore/ || error "Échec de la restauration du répertoire 'keystore'."
rsync -a "$EXTRACT_DIR/projects/" /var/lib/rundeck/projects/ || error "Échec de la restauration du répertoire 'projects'."
info "Restauration et fusion du répertoire de configuration..."
rsync -a "$EXTRACT_DIR/rundeck/" /etc/rundeck/ || error "Échec de la restauration du répertoire de configuration 'rundeck'."
success "Restauration des fichiers terminée."

# --- Rétablissement des permissions ---
info "Rétablissement des permissions pour les fichiers Rundeck..."
chown -R rundeck:rundeck /var/lib/rundeck /etc/rundeck
success "Permissions rétablies."

# --- Nettoyage ---
info "Nettoyage du répertoire d'extraction temporaire..."
rm -rf "$EXTRACT_DIR"
success "Répertoire temporaire supprimé."

# --- Redémarrage du service Rundeck ---
info "Redémarrage du service Rundeck..."
systemctl start rundeckd || error "Le redémarrage du service Rundeck a échoué."
success "Service Rundeck redémarré. La première initialisation peut prendre un certain temps."

end_success "Restauration de Rundeck terminée avec succès."