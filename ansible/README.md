# Déploiement Automatisé de la Stack Rundeck avec Ansible

Ce répertoire contient une collection de playbooks et de rôles **Ansible** conçus pour automatiser le déploiement d'une stack applicative complète, prête pour la production, autour de Rundeck. L'approche "Infrastructure as Code" garantit des déploiements **reproductibles, cohérents et fiables**.

## Architecture de la Stack

Le playbook principal (`site.yml`) déploie les composants suivants et les configure pour qu'ils fonctionnent de manière intégrée :

- **Rundeck** : Le cœur de l'orchestration, configuré pour utiliser MySQL comme base de données.
- **MySQL** : La base de données relationnelle pour stocker les données de Rundeck (jobs, exécutions, etc.).
- **Keycloak** : Un serveur d'authentification et de gestion des identités (SSO). Il est configuré pour s'intégrer avec Rundeck, centralisant ainsi la gestion des utilisateurs et des groupes.
- **MinIO** : Un stockage objet compatible S3, utilisé par Rundeck pour archiver les logs d'exécution des jobs.
- **Nginx** : Agit comme un reverse proxy pour Rundeck et Keycloak, gérant les certificats SSL/TLS et fournissant un point d'accès unique.
- **Java** : La dépendance principale pour faire fonctionner Rundeck.

## Prérequis

1.  **Machine de Contrôle Ansible :**
    *   Ansible >= 2.9.
    *   Accès SSH avec clé publique vers les serveurs cibles.

2.  **Serveurs Cibles :**
    *   Distribution basée sur Debian/Ubuntu (testé sur Ubuntu 20.04/22.04).
    *   Utilisateur avec privilèges `sudo` sans mot de passe.
    *   Python installé (généralement présent par défaut).

## Structure du Projet

Le projet suit la structure standard d'Ansible pour une meilleure organisation et modularité :

```
ansible/
├── inventory/
│   └── hosts.example   # Fichier d'exemple pour l'inventaire.
├── group_vars/
│   └── all.yml         # Fichier pour les variables globales.
├── roles/
│   ├── java/
│   ├── mysql/
│   ├── rundeck/
│   ├── nginx/
│   ├── keycloak/
│   └── minio/
├── site.yml            # Playbook principal qui déploie toute la stack.
└── README.md
```

## Configuration

### 1. Créer l'Inventaire

Copiez `inventory/hosts.example` vers `inventory/hosts` et définissez vos serveurs cibles.

**Exemple `inventory/hosts`:**
```ini
[rundeck_stack]
rundeck-master ansible_host=10.0.0.5 ansible_user=ubuntu
```

### 2. Personnaliser les Variables

La meilleure pratique consiste à ne **pas** modifier les `roles/../defaults/main.yml`. Surchargez plutôt les variables dans `group_vars/all.yml` ou dans des fichiers spécifiques à l'hôte (`host_vars/<hostname>.yml`).

**Exemple `group_vars/all.yml`:**
```yaml
# -- Variables MySQL --
db_name: "rundeck"
db_user: "rundeckuser"

# -- Variables Rundeck --
rundeck_version: "4.5.0"
rundeck_db_user: "{{ db_user }}"

# -- Variables Keycloak --
keycloak_version: "18.0"

# -- Domaines (IMPORTANT : à adapter) --
rundeck_domain: "rundeck.example.com"
keycloak_domain: "keycloak.example.com"
```

### 3. Gérer les Secrets (Mots de Passe)

Pour la production, il est **fortement recommandé** d'utiliser **Ansible Vault** pour chiffrer les mots de passe.

1.  **Créez un fichier de secrets chiffré :**
    ```bash
    ansible-vault create group_vars/secrets.yml
    ```

2.  **Ajoutez vos secrets dans ce fichier :**
    ```yaml
    # group_vars/secrets.yml (chiffré)
    db_password: "MonMotDePasseMySQL"
    rundeck_db_password: "{{ db_password }}"
    keycloak_admin_password: "MonMotDePasseKeycloakAdmin"
    minio_root_password: "MonMotDePasseMinIO"
    ```

## Utilisation

Toutes les commandes doivent être exécutées depuis le répertoire `ansible/`.

### Vérifier la Syntaxe et la Configuration (Dry Run)

Avant d'appliquer les changements, il est conseillé de faire une simulation avec l'option `--check`.

```bash
# Pour un déploiement avec vault
ansible-playbook -i inventory/hosts site.yml --check --ask-vault-pass

# Pour un déploiement sans vault
ansible-playbook -i inventory/hosts site.yml --check
```

### Déployer la Stack Complète

Le playbook `site.yml` est le point d'entrée principal pour un déploiement complet.

```bash
# Avec Vault
ansible-playbook -i inventory/hosts site.yml --ask-vault-pass

# Sans Vault
ansible-playbook -i inventory/hosts site.yml
```

### Exécution Granulaire avec les Tags

Chaque rôle est tagué avec son propre nom. Vous pouvez utiliser ces tags pour n'exécuter qu'une partie du déploiement. C'est très utile pour mettre à jour un seul composant.

**Exemple : Mettre à jour uniquement la configuration de Nginx :**
```bash
ansible-playbook -i inventory/hosts site.yml --tags "nginx"
```

**Exemple : Déployer Rundeck et sa base de données :**
```bash
ansible-playbook -i inventory/hosts site.yml --tags "mysql,rundeck"
```