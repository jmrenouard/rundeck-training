#!/bin/bash

# ==============================================================================
# Script: Installation de Gemini CLI sur Ubuntu
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
NODE_PCK_LIST="nodejs npm"
GEMINI_PCK="@google/gemini-cli"

# --- Début du script ---
start_script "### Installation de Gemini CLI ###"

# --- Tests Prérequis ---
info "Vérification des prérequis..."
if command -v gemini &>/dev/null; then
    warn "Gemini CLI semble déjà installé."
    gemini --version
    end_success "Gemini CLI est déjà présent sur le système."
fi
# --- Vérification et Installation de Node.js ---
if command -v node &>/dev/null; then
  info "Node.js est déjà installé (version: $(node --version))."
else
  info "Node.js n'est pas installé. Installation en cours..."
  info "Mise à jour du cache APT..."
  apt-get update >/dev/null || error "La mise à jour APT a échoué."
  info "Installation de Node.js..."
  apt-get install -y nodejs &>/dev/null || error "L'installation de Node.js a échoué."
  success "Node.js a été installé avec succès."
fi

# --- Vérification et Installation de NPM ---
if command -v npm &>/dev/null; then
  info "NPM est déjà installé (version: $(npm --version))."
else
  info "NPM n'est pas installé. Installation en cours..."
  apt-get install -y npm &>/dev/null || error "L'installation de NPM a échoué."
  success "NPM a été installé avec succès."
fi

# --- Installation de Gemini CLI ---
info "Installation de Gemini CLI via NPM..."
npm install -g $GEMINI_PCK &>/dev/null || error "L'installation de Gemini CLI a échoué."
success "Gemini CLI a été installé avec succès au niveau global."

# --- Tests Post-Installation ---
info "Validation de l'installation de Gemini CLI..."
if ! command -v gemini &>/dev/null; then
    error "La commande 'gemini' n'a pas été trouvée dans le PATH après l'installation. Essayez de recharger votre shell."
fi

info "Version de Gemini CLI installée :"
gemini --version || error "Impossible d'exécuter 'gemini --version'."
success "Gemini CLI est installé et fonctionnel."

end_success "Installation de Gemini CLI terminée avec succès."
