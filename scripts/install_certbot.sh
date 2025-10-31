#!/bin/bash

# ==============================================================================
# Script: Installation et Configuration de Certbot pour Nginx
# Auteur: Gemini
# Description: Ce script installe Certbot en utilisant pip et un environnement
#              virtuel Python. Il obtient ensuite un certificat Let's Encrypt
#              pour un domaine donné et configure Nginx automatiquement.
# Usage: ./install_certbot.sh <nom_dns_du_serveur> <email_admin>
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

# --- Vérification des paramètres ---
if [ -z "$1" ] || [ -z "$2" ]; then
    error "Le nom DNS et un email sont requis. Usage: $0 <server_name> <admin_email>"
fi

# --- Variables de Configuration ---
SERVER_NAME="$1"
ADMIN_EMAIL="$2"
PYTHON_VENV_PATH="/opt/certbot"

# --- Début du script ---
start_script "### Installation et Configuration de Certbot pour ${SERVER_NAME} ###"

# --- Vérification des droits ---
if [ "$(id -u)" -ne 0 ]; then
   error "Ce script doit être exécuté en tant que root. Veuillez utiliser 'sudo'."
fi
success "Vérification des droits root : OK."

# --- Tests Prérequis ---
info "Vérification des prérequis (Nginx, Python, port 80)..."
if ! command -v nginx &>/dev/null; then
    error "Nginx n'est pas installé. Veuillez exécuter le script 'install_nginx.sh' avant celui-ci."
fi
if ! command -v python3 &>/dev/null; then
    error "Python3 n'est pas trouvé. Veuillez l'installer (apt-get install python3)."
fi
if ! ss -tuln | grep -q ':80'; then
    warn "Le port 80 ne semble pas être ouvert ou écouté par Nginx. Certbot pourrait échouer."
fi
success "Prérequis validés."

# --- Installation des dépendances système ---
info "Mise à jour du cache APT et installation des dépendances..."
apt-get update >/dev/null
apt-get install -y python3 python3-dev python3-venv libaugeas-dev gcc &>/dev/null || error "L'installation des dépendances a échoué."
success "Dépendances système installées."

# --- Nettoyage d'anciennes installations de Certbot ---
info "Tentative de suppression d'anciennes versions de Certbot (via APT)..."
if dpkg -l | grep -q "certbot"; then
    apt-get remove -y certbot &>/dev/null
    success "Ancienne version de Certbot (APT) supprimée."
else
    info "Aucune version de Certbot via APT n'a été trouvée."
fi

# --- Création de l'environnement virtuel Python ---
info "Création de l'environnement virtuel Python dans ${PYTHON_VENV_PATH}..."
python3 -m venv "${PYTHON_VENV_PATH}" || error "La création de l'environnement virtuel a échoué."
info "Mise à jour de pip dans l'environnement virtuel..."
"${PYTHON_VENV_PATH}/bin/pip" install --upgrade pip &>/dev/null || error "La mise à jour de pip a échoué."
success "Environnement virtuel créé et pip mis à jour."

# --- Installation de Certbot ---
info "Installation de Certbot et du plugin Nginx via pip..."
"${PYTHON_VENV_PATH}/bin/pip" install certbot certbot-nginx &>/dev/null || error "L'installation de Certbot a échoué."
success "Certbot et le plugin Nginx ont été installés."

# --- Création du lien symbolique ---
info "Création du lien symbolique pour la commande certbot..."
ln -sf "${PYTHON_VENV_PATH}/bin/certbot" /usr/bin/certbot
success "Lien symbolique '/usr/bin/certbot' créé."

# --- Obtention du certificat ---
info "Lancement de Certbot pour obtenir le certificat pour ${SERVER_NAME}..."
warn "Certbot va maintenant tenter de configurer Nginx automatiquement."
warn "Assurez-vous que le DNS pour ${SERVER_NAME} pointe bien vers l'IP de ce serveur."

# Explication des options :
# --nginx : Utilise le plugin Nginx
# -d : Spécifie le domaine
# --non-interactive : N'attend pas de saisie utilisateur
# --agree-tos : Accepte les conditions d'utilisation
# -m : Spécifie l'email pour les notifications
# --redirect : Configure Nginx pour rediriger HTTP vers HTTPS
certbot --nginx -d "${SERVER_NAME}" --non-interactive --agree-tos -m "${ADMIN_EMAIL}" --redirect || error "L'obtention du certificat a échoué."
success "Certificat obtenu et Nginx configuré pour ${SERVER_NAME}."

# --- Configuration du renouvellement automatique ---
info "Configuration du renouvellement automatique via crontab..."
CRON_JOB="0 0,12 * * * root ${PYTHON_VENV_PATH}/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q"
if ! grep -q "certbot renew" /etc/crontab; then
    echo "${CRON_JOB}" >> /etc/crontab
    success "Tâche cron pour le renouvellement de Certbot ajoutée."
else
    warn "Une tâche de renouvellement pour Certbot semble déjà exister dans crontab."
fi

# --- Validation de la configuration Nginx post-Certbot ---
info "Validation de la configuration Nginx après modification par Certbot..."
if ! nginx -t &>/dev/null; then
    error "La configuration Nginx est invalide après l'intervention de Certbot. Vérifiez les fichiers de configuration."
fi
success "Configuration Nginx post-Certbot validée."

# --- Validation finale ---
info "Redémarrage de Nginx pour s'assurer que tout est pris en compte..."
systemctl restart nginx
info "Validation finale du service..."
if ! ss -tuln | grep -q ':443'; then error "Nginx n'écoute pas sur le port 443 après la configuration de Certbot."; fi
success "Le port 443 est bien ouvert et écouté par Nginx."

end_success "Installation et configuration de Certbot terminées pour ${SERVER_NAME}."