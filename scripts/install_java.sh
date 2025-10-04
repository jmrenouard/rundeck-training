#!/bin/bash

# ==============================================================================
# Script: Installation de Java pour Rundeck
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

# --- Liste des Paquets ---
# OpenJDK 11 est recommandé pour les versions récentes de Rundeck
PCK_LIST="openjdk-11-jdk"

# --- Début du script ---
start_script "### Étape 1 : Installation de Java (OpenJDK 11) ###"

# --- Tests Prérequis ---
info "Vérification des prérequis..."
if command -v java &>/dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    info "Java est déjà installé. Version détectée : $JAVA_VERSION"
    if [[ "$JAVA_VERSION" == "11."* ]]; then
        success "La version 11 de Java est déjà installée. Aucune action n'est requise."
        end_success "Installation de Java déjà conforme."
    else
        warn "Une autre version de Java est installée. Le script va installer OpenJDK 11."
    fi
else
    info "Java n'est pas encore installé."
fi
success "Prérequis validés."

# --- Installation ---
info "Mise à jour du cache APT et installation des dépendances..."
apt-get update >/dev/null
apt-get install -y software-properties-common apt-transport-https wget gpg &>/dev/null || error "L'installation des dépendances a échoué."
success "Dépendances installées."

info "Installation de la suite de paquets..."
for pck in $PCK_LIST; do
  echo " * Installation de $pck..."
  apt-get install -y "$pck" &>/dev/null || error "L'installation du paquet '$pck' a échoué."
  success "Le paquet '$pck' a été installé avec succès."
done
success "Tous les paquets ont été installés."

# --- Tests Post-Installation ---
info "Validation de l'installation..."
if ! command -v java &>/dev/null; then
    error "La commande 'java' n'a pas été trouvée après l'installation."
fi

JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
if [[ "$JAVA_VERSION" != "11."* ]]; then
    error "La version de Java installée n'est pas la 11. Version actuelle : $JAVA_VERSION"
fi
success "Java version 11 est correctement installée."

# --- Configuration de JAVA_HOME ---
info "Configuration de la variable d'environnement JAVA_HOME..."
JAVA_BIN_PATH=$(readlink -f "$(which java)")
JAVA_HOME_PATH=$(dirname "$(dirname "$JAVA_BIN_PATH")")
if [ -z "$JAVA_HOME_PATH" ] || [ ! -d "$JAVA_HOME_PATH" ]; then
    error "Impossible de déterminer le chemin d'installation de Java 11 via readlink."
fi

if ! grep -q "export JAVA_HOME=" /etc/environment; then
    echo "export JAVA_HOME=$JAVA_HOME_PATH" >> /etc/environment
    info "JAVA_HOME a été ajouté à /etc/environment."
else
    sed -i "/^export JAVA_HOME=/c\export JAVA_HOME=$JAVA_HOME_PATH" /etc/environment
    info "JAVA_HOME a été mis à jour dans /etc/environment."
fi
source /etc/environment
success "La variable JAVA_HOME a été configurée : $JAVA_HOME"

end_success "Installation et configuration de Java terminées avec succès."