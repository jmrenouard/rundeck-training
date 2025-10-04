#!/bin/bash

# ==============================================================================
# Script: Installation de MySQL pour Rundeck
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

# --- Variables de Configuration (À MODIFIER POUR LA PRODUCTION) ---
DB_NAME="rundeck"
DB_USER="rundeckuser"
DB_PASS="rundeckpassword" # Attention: Utiliser un mot de passe fort en production.

# --- Liste des Paquets ---
PCK_LIST="mysql-server"

# --- Début du script ---
start_script "### Étape 2 : Installation et Configuration de MySQL ###"

# --- Tests Prérequis ---
info "Vérification des prérequis..."
if command -v mysql &>/dev/null; then
    warn "MySQL semble déjà installé. Le script vérifiera la configuration pour Rundeck."
fi
success "Prérequis validés."

# --- Installation ---
info "Mise à jour du cache APT..."
apt-get update >/dev/null
info "Installation de MySQL Server..."
apt-get install -y $PCK_LIST &>/dev/null || error "L'installation de MySQL a échoué."
success "MySQL a été installé avec succès."

# --- Démarrage et Activation du Service ---
info "Démarrage et activation du service MySQL..."
systemctl enable mysql
systemctl start mysql || error "Le démarrage du service MySQL a échoué."
success "Le service MySQL a été démarré et activé."

# --- Pause pour démarrage ---
info "Pause de 10 secondes pour laisser le temps à MySQL de démarrer..."
sleep 10s

# --- Tests Post-Installation ---
info "Validation de l'installation de MySQL..."
if ! systemctl is-active --quiet mysql; then error "Le service MySQL n'a pas pu démarrer."; fi
if ! ss -tuln | grep -q ':3306'; then error "MySQL n'écoute pas sur le port 3306."; fi
success "MySQL est actif et répond correctement."

# --- Configuration de la base de données ---
info "Configuration de la base de données et de l'utilisateur pour Rundeck..."
warn "Le mot de passe root de MySQL n'est pas défini par ce script. mysql_secure_installation est recommandé."

# Création de la base de données et de l'utilisateur
# Utilisation d'un bloc 'heredoc' pour passer les commandes SQL
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

if [ $? -ne 0 ]; then
    error "La création de la base de données ou de l'utilisateur a échoué."
fi
success "Base de données '$DB_NAME' et utilisateur '$DB_USER' créés avec succès."

# --- Validation de la configuration ---
info "Vérification de l'accès à la base de données avec le nouvel utilisateur..."
if ! mysql -u"$DB_USER" -p"$DB_PASS" -e "use $DB_NAME;"; then
    error "Impossible de se connecter à la base de données '$DB_NAME' avec l'utilisateur '$DB_USER'."
fi
success "La connexion à la base de données Rundeck a été vérifiée avec succès."

end_success "Installation et configuration de MySQL pour Rundeck terminées."