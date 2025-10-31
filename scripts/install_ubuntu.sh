#!/bin/bash

# ==============================================================================
# Script Principal: Installation complète de la stack Rundeck sur Ubuntu
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

# --- Variables ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LOG_FILE="/var/log/rundeck_install_$(date +%Y%m%d_%H%M%S).loSERVER_NAME=""
ADMIN_EMAIL=""

# --- Scripts à exécuter ---
INSTALL_SCRIPTS=(
    "install_java.sh"
    "install_mysql.sh"
    "install_rundeck.sh"
    "install_nginx.sh"
    "install_certbot.sh"
)

# --- Fonctions du script principal ---
execute_script() {
    local script_name=$1
    local script_path="$SCRIPT_DIR/$script_name"

    if [ ! -f "$script_path" ]; then
        error "Le script requis '$script_name' est introuvable dans le répertoire '$SCRIPT_DIR'."
    fi

    info "Exécution du script : $script_name..."
    # Rendre le script exécutable
    chmod +x "$script_path"

    # Exécuter le script et rediriger la sortie vers le fichier de log et stdout/stderr
    # Passer les arguments nécessaires aux scripts qui en ont besoin
    local args=()
    [[ "$script_name" == "install_nginx.sh" || "$script_name" == "install_certbot.sh" ]] && args+=("$SERVER_NAME")
    [[ "$script_name" == "install_certbot.sh" ]] && args+=("$ADMIN_EMAIL")

    if ! bash "$script_path" "${args[@]}" | tee -a "$LOG_FILE"; then
        error "L'exécution du script '$script_name' a échoué. Consultez '$LOG_FILE' pour plus de détails."
    fi
    success "Le script '$script_name' a été exécuté avec succès."
}

# --- Début du script ---
start_script "### Installation Complète de la Stack Rundeck sur Ubuntu ###"
info "Les logs détaillés de cette installation seront enregistrés dans : $LOG_FILE"
touch "$LOG_FILE" || error "Impossible de créer le fichier de log. Vérifiez les permissions."

# --- Vérification des droits ---
if [ "$(id -u)" -ne 0 ]; then
   error "Ce script doit être exécuté en tant que root. Veuillez utiliser 'sudo'."
fi
success "Vérification des droits root : OK."

# --- Demande des informations utilisateur ---
info "Veuillez fournir les informations suivantes pour la configuration de Nginx et Certbot."
while [ -z "$SERVER_NAME" ]; do
    read -p "Entrez le nom de domaine complet (ex: rundeck.votredomaine.com): " SERVER_NAME
    [ -z "$SERVER_NAME" ] && warn "Le nom de domaine ne peut pas être vide."
done

while [ -z "$ADMIN_EMAIL" ]; do
    read -p "Entrez votre adresse email (pour les alertes Certbot): " ADMIN_EMAIL
    [ -z "$ADMIN_EMAIL" ] && warn "L'adresse email ne peut pas être vide."
done
success "Informations enregistrées : Domaine=${SERVER_NAME}, Email=${ADMIN_EMAIL}"

# --- Exécution des scripts d'installation ---
for script in "${INSTALL_SCRIPTS[@]}"; do
    execute_script "$script"
    info "Pause de 5 secondes avant le prochain script..."
    sleep 5
done

# --- Message de fin ---
SERVER_IP=$(hostname -I | awk '{print $1}')
success "========================================================================"
success "Installation de la stack Rundeck terminée !"
success "URL de Rundeck : https://${SERVER_NAME}"
success "Login par défaut : admin"
success "Mot de passe par défaut : admin"
warn "N'oubliez pas de changer le mot de passe par défaut et de sécuriser votre installation MySQL."
success "========================================================================"

end_success "Tous les scripts ont été exécutés avec succès."