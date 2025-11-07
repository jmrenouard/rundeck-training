#!/bin/bash

# Script pour installer et configurer un Runner Rundeck en tant que service systemd.
#
# Ce script prend en charge :
# - La validation des paramètres d'entrée.
# - L'installation des dépendances (Java, curl, jq).
# - La recherche de l'ID du runner via l'API Rundeck.
# - Le téléchargement du fichier .jar du runner.
# - La création et la gestion d'un service systemd pour le runner.

# Arrête le script si une commande échoue
set -e
# Gère les erreurs dans les pipelines
set -o pipefail

# --- Définition des couleurs pour les logs ---
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'

# --- Fonctions de logging ---
info() {
    echo -e "${C_BLUE}[INFO] ${1}${C_RESET}"
}

success() {
    echo -e "${C_GREEN}[SUCCESS] ${1}${C_RESET}"
}

warn() {
    echo -e "${C_YELLOW}[WARNING] ${1}${C_RESET}"
}

error() {
    echo -e "${C_RED}[ERROR] ${1}${C_RESET}" >&2
    exit 1
}

# --- Fonction d'usage ---
usage() {
    echo "Usage: $0 <RUNDECK_URL> <API_TOKEN> <RUNNER_NAME>"
    echo "Exemple: $0 https://rundeck.example.com your-api-token my-runner-01"
    exit 1
}

# --- Début du script ---
info "Démarrage du script d'installation du Runner Rundeck..."

# --- Validation des paramètres ---
if [ "$#" -ne 3 ]; then
    error "Nombre de paramètres incorrect."
    usage
fi

RUNDECK_URL="$1"
API_TOKEN="$2"
RUNNER_NAME="$3"

info "Paramètres fournis :"
echo -e "  - URL Rundeck: ${C_YELLOW}${RUNDECK_URL}${C_RESET}"
echo -e "  - Nom du Runner: ${C_YELLOW}${RUNNER_NAME}${C_RESET}"

# --- Vérification des prérequis ---
info "Vérification des prérequis (root, Java, curl, jq)..."

if [ "$EUID" -ne 0 ]; then
  error "Ce script doit être exécuté en tant que root (ou avec sudo)."
fi

if ! command -v java &> /dev/null; then
    info "Java n'est pas installé. Installation de default-jre..."
    apt-get update && apt-get install -y default-jre
    success "Java (default-jre) a été installé."
else
    success "Java est déjà installé."
fi

if ! command -v curl &> /dev/null; then
    info "curl n'est pas installé. Installation..."
    apt-get update && apt-get install -y curl
    success "curl a été installé."
else
    success "curl est déjà installé."
fi

if ! command -v jq &> /dev/null; then
    info "jq n'est pas installé. Installation..."
    apt-get update && apt-get install -y jq
    success "jq a été installé."
else
    success "jq est déjà installé."
fi

# --- Configuration du répertoire ---
RUNNER_DIR="/opt/runner/${RUNNER_NAME}"
info "Configuration du répertoire d'installation : ${RUNNER_DIR}"
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# --- Récupération de l'ID du Runner ---
info "Recherche de l'ID pour le runner nommé '${RUNNER_NAME}'..."

# L'API Rundeck peut nécessiter un numéro de version, ici 56 est utilisé comme dans votre exemple.
# Vous devrez peut-être l'adapter à votre version de Rundeck.
API_VERSION="56"

RUNNER_ID=$(curl -s -G \
  --header "X-Rundeck-Auth-Token: ${API_TOKEN}" \
  "${RUNDECK_URL}/api/${API_VERSION}/runnerManagement/runners" | jq -r --arg name "${RUNNER_NAME}" '.[] | select(.name == $name) | .id')

if [ -z "$RUNNER_ID" ]; then
    error "Aucun runner trouvé avec le nom '${RUNNER_NAME}'. Veuillez vérifier le nom et vous assurer qu'il est enregistré dans Rundeck."
fi

success "Runner trouvé ! ID : ${RUNNER_ID}"

# --- Téléchargement du Runner ---
JAR_FILE="runner-${RUNNER_ID}.jar"
info "Téléchargement du runner (ID: ${RUNNER_ID}) vers '${JAR_FILE}'..."

curl -s --fail \
  --header "X-Rundeck-Auth-Token: ${API_TOKEN}" \
  "${RUNDECK_URL}/api/${API_VERSION}/runnerManagement/download/${RUNNER_ID}" \
  --output "${JAR_FILE}"

if [ ! -f "$JAR_FILE" ]; then
    error "Le téléchargement du runner a échoué."
fi

success "Le fichier du runner a été téléchargé avec succès."

# --- Création du service systemd ---
SERVICE_NAME="rundeck-runner-${RUNNER_NAME}"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
info "Création du fichier de service systemd : ${SERVICE_FILE}"

cat << EOF > "$SERVICE_FILE"
[Unit]
Description=Rundeck Runner - ${RUNNER_NAME}
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=${RUNNER_DIR}
ExecStart=/usr/bin/java -jar ${RUNNER_DIR}/${JAR_FILE}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

success "Fichier de service créé."

# --- Démarrage du service ---
info "Rechargement de systemd et activation/démarrage du service '${SERVICE_NAME}'..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# Attente de quelques secondes pour laisser le temps au service de démarrer
sleep 5

# --- Vérification du statut ---
if systemctl is-active --quiet "$SERVICE_NAME"; then
    success "Le service '${SERVICE_NAME}' a démarré avec succès et est actif."
    info "Pour vérifier les logs, utilisez : journalctl -u ${SERVICE_NAME} -f"
    info "Pour arrêter le service, utilisez : systemctl stop ${SERVICE_NAME}"
else
    error "Le service '${SERVICE_NAME}' n'a pas pu démarrer. Vérifiez les logs avec 'journalctl -u ${SERVICE_NAME}'."
fi

info "Installation du Runner Rundeck terminée."