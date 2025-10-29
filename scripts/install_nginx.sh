#!/bin/bash

# ==============================================================================
# Script: Installation et Configuration de Nginx pour Rundeck
# Auteur: Gemini
# Description: Ce script installe Nginx et le configure comme un reverse proxy
#              SSL pour une instance Rundeck écoutant sur http://localhost:4440.
#              Il génère des certificats auto-signés s'ils n'existent pas.
# Usage: ./install_nginx.sh <nom_dns_du_serveur>
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
if [ -z "$1" ]; then
    error "Le nom DNS du serveur est requis. Usage: $0 <server_name>"
fi

# --- Variables de Configuration ---
SERVER_NAME="$1"
PCK_LIST="nginx"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
NGINX_CONF_FILE="${NGINX_CONF_DIR}/${SERVER_NAME}"
SSL_CERT="/etc/ssl/certs/${SERVER_NAME}.crt"
SSL_KEY="/etc/ssl/private/${SERVER_NAME}.key"


# --- Début du script ---
start_script "### Installation et Configuration de Nginx pour Rundeck ###"

# --- Tests Prérequis ---
info "Vérification des prérequis..."
if ! command -v nginx &>/dev/null; then
    info "Nginx n'est pas installé. L'installation va commencer."
else
    warn "Nginx semble déjà installé. Le script vérifiera la configuration."
fi
if ! command -v openssl &>/dev/null; then
    error "openssl n'est pas trouvé. Veuillez l'installer (apt-get install openssl)."
fi
success "Prérequis validés."

# --- Installation ---
info "Mise à jour du cache APT..."
apt-get update >/dev/null
info "Installation de Nginx..."
apt-get install -y $PCK_LIST &>/dev/null || error "L'installation de Nginx a échoué."
success "Nginx a été installé avec succès."

# --- Démarrage et Activation du Service ---
info "Démarrage et activation du service Nginx..."
systemctl enable nginx
systemctl start nginx || error "Le démarrage du service Nginx a échoué."
success "Le service Nginx a été démarré et activé."

# --- Tests Post-Installation ---
info "Validation de l'installation de Nginx..."
if ! systemctl is-active --quiet nginx; then error "Le service Nginx n'a pas pu démarrer."; fi
if ! ss -tuln | grep -q ':80'; then warn "Nginx n'écoute pas sur le port 80. Vérification nécessaire."; fi
success "Nginx est actif."

# --- Configuration de Nginx ---
info "Configuration de Nginx en tant que reverse proxy pour ${SERVER_NAME}..."

# --- Génération de certificats SSL auto-signés (si non existants) ---
if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    warn "Certificats SSL non trouvés. Génération de certificats auto-signés."
    warn "Ces certificats ne sont PAS sécurisés pour un environnement de production."
    mkdir -p /etc/ssl/private
    chmod 700 /etc/ssl/private
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_KEY" \
        -out "$SSL_CERT" \
        -subj "/C=FR/ST=IDF/L=Paris/O=Lab/OU=IT/CN=${SERVER_NAME}"
else
    info "Certificats SSL existants trouvés pour ${SERVER_NAME}."
fi

# --- Création du fichier de configuration Nginx ---
info "Création du fichier de configuration : ${NGINX_CONF_FILE}"
cat << EOF > "${NGINX_CONF_FILE}"
server {
    listen 443 ssl;
    server_name ${SERVER_NAME};

    # Certificats SSL
    ssl_certificate ${SSL_CERT};
    ssl_certificate_key ${SSL_KEY};

    # Renforcez la sécurité SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Configuration du reverse proxy
    location / {
        proxy_pass http://localhost:4440;

        proxy_set_header X-Forwarded-Host \$host:\$server_port;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # Support pour WebSocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
   }
}

server {
    listen 80;
    server_name ${SERVER_NAME};

    # Redirection HTTP vers HTTPS
    return 301 https://\$host\$request_uri;
}
EOF
success "Fichier de configuration créé."

# --- Activation du site ---
info "Activation du site ${SERVER_NAME}..."
ln -sf "${NGINX_CONF_FILE}" "${NGINX_ENABLED_DIR}/"
# Suppression de la configuration par défaut si elle existe et est un lien symbolique
if [ -L "${NGINX_ENABLED_DIR}/default" ]; then
    info "Suppression de la configuration Nginx par défaut."
    rm -f "${NGINX_ENABLED_DIR}/default"
fi
success "Site activé."

# --- Validation et redémarrage de Nginx ---
info "Validation de la configuration Nginx..."
if ! nginx -t; then
    error "La configuration de Nginx est invalide. Veuillez vérifier le fichier ${NGINX_CONF_FILE}."
fi
success "Configuration Nginx validée."

info "Redémarrage du service Nginx pour appliquer la nouvelle configuration..."
systemctl restart nginx || error "Le redémarrage de Nginx a échoué."
success "Nginx a été redémarré avec succès."

# --- Validation finale ---
info "Validation finale du service..."
if ! ss -tuln | grep -q ':443'; then warn "Nginx n'écoute pas sur le port 443. Vérification nécessaire."; fi
success "Le port 443 est maintenant ouvert."

end_success "Installation et configuration de Nginx pour Rundeck terminées."
