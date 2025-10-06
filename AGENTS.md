# Directives pour l'Agent IA (Jules)

Ce document définit les principes et les standards que tu dois suivre pour contribuer à ce projet. L'objectif est de construire un dépôt de formation de haute qualité, contenant des outils de configuration, d'installation et de démonstration qui soient à la fois simples, efficaces et robustes.

## 1. Principes Généraux

- **Qualité et Fiabilité** : Chaque script, configuration ou documentation doit être testé et vérifié. Le code doit être robuste et gérer les erreurs potentielles de manière explicite.
- **Simplicité et Clarté** : Préfère toujours les solutions simples et directes. Le code et les configurations doivent être faciles à comprendre pour un utilisateur ayant des connaissances de base sur les technologies concernées (Docker, Ansible, Bash, etc.).
- **Efficacité** : Les outils fournis doivent être optimisés pour atteindre leur objectif rapidement et sans étapes superflues.

## 2. Standards de Développement

### Langue et Documentation

- **Français d'abord** : Toute la documentation, les commentaires dans le code, les messages affichés à l'utilisateur et les fichiers `README.md` doivent être rédigés en français.
- **Commentaires Pertinents** : Commente le code pour expliquer le "pourquoi" et non le "comment". Chaque script, `docker-compose.yml`, `Dockerfile` ou playbook Ansible doit être commenté.
- **README exhaustifs** : Chaque composant principal (ex: `docker/`, `ansible/`, `scripts/`) doit avoir son propre `README.md` expliquant son rôle, son contenu et son mode d'emploi. Le `README.md` principal à la racine doit servir de portail vers les autres.

### Scripts (Bash, PowerShell)

- **Modèle Standard** : Suis le modèle de script bash existant, incluant `set -e`, `set -o pipefail`, et les fonctions de logging colorées (`info`, `success`, `warn`, `error`).
- **Prérequis et Dépendances** : Chaque script doit vérifier ses prérequis (ex: Docker est installé, un fichier existe) avant de commencer son exécution principale.
- **Idempotence** : Lorsque c'est possible, conçois les scripts pour qu'ils puissent être exécutés plusieurs fois sans causer d'erreur si l'état désiré est déjà atteint.

### Environnement Docker

- **Externalisation de la Configuration** : Utilise un fichier `.env` pour gérer les variables d'environnement (ports, mots de passe, chemins de volumes). Fournis systématiquement un fichier `.env.example` comme modèle.
- **Modularité** : Sépare les environnements lorsque c'est pertinent (par exemple, un `docker-compose.yml` pour le développement local, un `docker-swarm.yml` pour un déploiement en production).
- **Gestion Simplifiée** : Fournis un `Makefile` dans le répertoire `docker/` pour simplifier les commandes courantes (`up`, `down`, `logs`, `clean`).

### Ansible

- **Structure Standard** : Respecte la structure de répertoires standard des rôles Ansible (`tasks`, `handlers`, `templates`, `defaults`, `meta`, `files`).
- **Variables** : Rends les rôles configurables en utilisant des variables définies dans `defaults/main.yml` et `vars/main.yml`.
- **Validation** : Intègre des étapes de validation avant d'appliquer des changements critiques (ex: `nginx -t` avant de recharger le service).

## 3. Objectif Final

L'objectif de ce dépôt est de servir de **ressource pédagogique**. Chaque contribution doit être pensée dans ce sens. Un utilisateur doit pouvoir cloner le dépôt, lire la documentation et, en suivant des étapes simples et claires, déployer un environnement fonctionnel pour apprendre et expérimenter.

Jules, ton rôle est de t'assurer que chaque nouvelle fonctionnalité respecte ces directives à la lettre.