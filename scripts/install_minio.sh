#!/bin/bash

# ==============================================================================
# Script: Installation de MinIO
# ==============================================================================
# Ce script installe et configure un serveur MinIO autonome.
# Il télécharge le binaire, crée un utilisateur de service, configure les
# répertoires et met en place un service systemd pour le gérer.
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

# --- Variables de Configuration ---
MINIO_USER="minio-user"
MINIO_GROUP="minio-user"
MINIO_CONFIG_DIR="/etc/minio"
MINIO_DATA_DIR="/var/minio"
MINIO_BINARY_PATH="/usr/local/bin/minio"

# --- Début du script ---
start_script "### Étape 3 : Installation de MinIO ###"

# --- Tests Prérequis ---
info "Vérification des prérequis..."
if command -v minio &>/dev/null; then
    warn "La commande 'minio' est déjà disponible. Le script continuera, mais une installation existante pourrait être modifiée."
else
    info "MinIO n'est pas encore installé."
fi
success "Prérequis validés."

# --- Création de l'Utilisateur et du Groupe ---
info "Création de l'utilisateur et du groupe de service MinIO..."
if id "$MINIO_USER" &>/dev/null; then
    warn "L'utilisateur '$MINIO_USER' existe déjà."
else
    groupadd -r "$MINIO_GROUP"
    useradd -r -g "$MINIO_GROUP" -s /sbin/nologin -M -c "Utilisateur pour le service MinIO" "$MINIO_USER"
    info "Utilisateur '$MINIO_USER' et groupe '$MINIO_GROUP' créés."
fi
success "Utilisateur et groupe configurés."

# --- Création des Répertoires ---
info "Création des répertoires de configuration et de données..."
mkdir -p "$MINIO_CONFIG_DIR" || error "Impossible de créer le répertoire de configuration."
mkdir -p "$MINIO_DATA_DIR" || error "Impossible de créer le répertoire de données."
chown -R "${MINIO_USER}:${MINIO_GROUP}" "$MINIO_CONFIG_DIR" "$MINIO_DATA_DIR"
chmod -R 750 "$MINIO_CONFIG_DIR" "$MINIO_DATA_DIR"
success "Répertoires créés et permissions appliquées."

# --- Téléchargement du Binaire ---
info "Téléchargement du binaire MinIO..."
wget -q "https://dl.min.io/server/minio/release/linux-amd64/minio" -O "$MINIO_BINARY_PATH" || error "Le téléchargement du binaire MinIO a échoué."
chmod +x "$MINIO_BINARY_PATH"
success "Binaire MinIO téléchargé et rendu exécutable."

# --- Création du Fichier d'Environnement ---
info "Création du fichier d'environnement pour les secrets..."
MINIO_ROOT_USER="minio"
MINIO_ROOT_PASSWORD="minio_password"
ENV_FILE="$MINIO_CONFIG_DIR/minio.env"
echo "MINIO_ROOT_USER=${MINIO_ROOT_USER}" > "$ENV_FILE"
echo "MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}" >> "$ENV_FILE"
chown "${MINIO_USER}:${MINIO_GROUP}" "$ENV_FILE"
chmod 640 "$ENV_FILE"
warn "Un fichier d'environnement a été créé dans '$ENV_FILE' avec des identifiants par défaut."
warn "CHANGEZ CES IDENTIFIANTS pour un environnement de production !"
success "Fichier d'environnement créé."

# --- Création du Service Systemd ---
info "Création du fichier de service systemd..."
SERVICE_FILE="/etc/systemd/system/minio.service"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=MinIO Object Storage Server
Documentation=https://docs.min.io
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=${MINIO_USER}
Group=${MINIO_GROUP}
WorkingDirectory=${MINIO_DATA_DIR}
EnvironmentFile=${MINIO_CONFIG_DIR}/minio.env
ExecStart=${MINIO_BINARY_PATH} server ${MINIO_DATA_DIR} --console-address ":9001"

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
success "Fichier de service systemd créé."

# --- Démarrage du Service ---
info "Rechargement de systemd et démarrage du service MinIO..."
systemctl daemon-reload
systemctl enable minio >/dev/null
systemctl start minio
success "Service MinIO activé et démarré."

# --- Tests Post-Installation ---
info "Validation de l'installation..."
if ! systemctl is-active --quiet minio; then
    error "Le service MinIO n'est pas actif après le démarrage."
fi
if ! ss -tuln | grep -q ':9000'; then
    error "MinIO n'écoute pas sur le port 9000."
fi
if ! ss -tuln | grep -q ':9001'; then
    error "La console MinIO n'écoute pas sur le port 9001."
fi
success "Le service MinIO est en cours d'exécution et écoute sur les ports 9000 (API) et 9001 (Console)."

end_success "Installation de MinIO terminée avec succès."