#!/bin/bash

# ==============================================================================
# Script: Optimisation de Linux pour Rundeck
# Auteur: Gemini
# Description: Ce script ajuste les limites de descripteurs de fichiers (file
#              descriptors) pour l'utilisateur exécutant Rundeck, afin d'éviter
#              l'erreur "Too many open files".
# Usage: ./tuning_linux.sh [utilisateur_rundeck]
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
RUNDECK_USER=${1:-"rundeck"}
NEW_LIMIT=65535
LIMITS_CONF="/etc/security/limits.conf"

# --- Début du script ---
start_script "### Optimisation des descripteurs de fichiers pour l'utilisateur ${RUNDECK_USER} ###"

# --- Vérification des droits ---
if [ "$(id -u)" -ne 0 ]; then
   error "Ce script doit être exécuté en tant que root. Veuillez utiliser 'sudo'."
fi
success "Vérification des droits root : OK."

# --- Vérification des prérequis ---
info "Vérification de l'existence du fichier ${LIMITS_CONF}..."
if [ ! -f "${LIMITS_CONF}" ]; then
    error "Le fichier de configuration '${LIMITS_CONF}' n'a pas été trouvé."
fi
success "Fichier de configuration trouvé."

# --- Vérification de l'utilisateur ---
info "Vérification de l'existence de l'utilisateur '${RUNDECK_USER}'..."
if ! id "${RUNDECK_USER}" &>/dev/null; then
    warn "L'utilisateur '${RUNDECK_USER}' n'existe pas. La configuration sera ajoutée, mais assurez-vous que le nom d'utilisateur est correct."
fi
success "Vérification de l'utilisateur terminée."

# --- Augmentation de la limite de descripteurs de fichiers ---
info "Vérification de la configuration existante pour '${RUNDECK_USER}' dans ${LIMITS_CONF}..."

# Vérifie si une configuration pour 'nofile' existe déjà pour cet utilisateur
if grep -q "^${RUNDECK_USER}.*nofile" "${LIMITS_CONF}"; then
    warn "Une configuration pour 'nofile' pour l'utilisateur '${RUNDECK_USER}' existe déjà dans ${LIMITS_CONF}."
    info "Lignes existantes :"
    grep "^${RUNDECK_USER}.*nofile" "${LIMITS_CONF}" | while read -r line; do info "  $line"; done
    warn "Le script ne modifiera pas la configuration existante. Veuillez vérifier manuellement."
else
    info "Aucune configuration 'nofile' trouvée pour '${RUNDECK_USER}'. Ajout de la nouvelle configuration..."
    # Ajout des nouvelles limites à la fin du fichier
    echo "" >> "${LIMITS_CONF}"
    echo "# Limites pour Rundeck (ajouté par le script tuning_linux.sh)" >> "${LIMITS_CONF}"
    echo "${RUNDECK_USER} hard nofile ${NEW_LIMIT}" >> "${LIMITS_CONF}"
    echo "${RUNDECK_USER} soft nofile ${NEW_LIMIT}" >> "${LIMITS_CONF}"
    success "Les limites de descripteurs de fichiers ont été définies à ${NEW_LIMIT} pour l'utilisateur '${RUNDECK_USER}'."
fi

# --- Augmentation de la limite au niveau du système (optionnel) ---
info "Vérification de la limite de descripteurs de fichiers au niveau du système..."
SYSTEM_MAX_FILES=$(cat /proc/sys/fs/file-max)
info "Limite actuelle du système (fs.file-max): ${SYSTEM_MAX_FILES}"
if [ "${SYSTEM_MAX_FILES}" -lt "${NEW_LIMIT}" ]; then
    warn "La limite globale du système est inférieure à la nouvelle limite pour l'utilisateur."
    info "Augmentation de la limite système à ${NEW_LIMIT} (temporaire, pour la session en cours)..."
    # La modification via /proc/sys/fs/file-max n'est pas permanente.
    # Pour la rendre permanente, il faut l'ajouter à /etc/sysctl.conf
    echo "${NEW_LIMIT}" > /proc/sys/fs/file-max
    if ! grep -q "^fs.file-max" /etc/sysctl.conf; then
        info "Pour rendre cette modification permanente, ajout de 'fs.file-max = ${NEW_LIMIT}' à /etc/sysctl.conf..."
        echo "" >> /etc/sysctl.conf
        echo "# Augmenter la limite globale de descripteurs de fichiers pour Rundeck" >> /etc/sysctl.conf
        echo "fs.file-max = ${NEW_LIMIT}" >> /etc/sysctl.conf
        # Appliquer la configuration sysctl
        sysctl -p
    else
        warn "La configuration 'fs.file-max' existe déjà dans /etc/sysctl.conf. Vérification manuelle recommandée."
    fi
    success "Limite système de descripteurs de fichiers mise à jour."
else
    success "La limite globale du système est suffisante."
fi

# --- Message final ---
warn "Les modifications dans '${LIMITS_CONF}' nécessitent une nouvelle session pour être appliquées."
warn "Vous devez vous déconnecter et vous reconnecter avec l'utilisateur '${RUNDECK_USER}', ou redémarrer le système."
info "Après redémarrage du service Rundeck, vous pouvez vérifier la nouvelle limite avec la commande :"
info "  sudo -u ${RUNDECK_USER} ulimit -n"

end_success "Optimisation des descripteurs de fichiers terminée."
