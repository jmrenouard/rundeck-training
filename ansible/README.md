# Déploiement d'une Stack Applicative avec Ansible

Ce projet Ansible permet de déployer une stack complète incluant Java, MySQL, Rundeck, Nginx, Keycloak et MinIO. Il est conçu pour être modulaire, vous permettant de déployer la stack entière ou seulement les composants dont vous avez besoin.

## Prérequis

1.  **Machine de Contrôle Ansible :**
    *   Ansible doit être installé.
    *   Accès SSH avec clé publique aux serveurs cibles.

2.  **Serveurs Cibles :**
    *   Une distribution basée sur Debian/Ubuntu.
    *   Un utilisateur avec des privilèges `sudo` sans mot de passe.
    *   Python 2.x ou 3.x doit être installé (généralement présent par défaut).

## Structure des Fichiers

Le répertoire `ansible/` est organisé comme suit :

```
ansible/
├── inventory/
│   └── hosts           # Fichier d'inventaire pour définir vos serveurs cibles.
├── playbooks/
│   ├── site.yml        # Playbook principal pour déployer toute la stack.
│   ├── java.yml        # Playbook pour installer Java uniquement.
│   ├── mysql.yml       # Playbook pour installer MySQL uniquement.
│   ├── rundeck.yml     # Playbook pour installer Rundeck et ses dépendances.
│   ├── nginx.yml       # Playbook pour installer et configurer Nginx.
│   ├── keycloak.yml    # Playbook pour déployer Keycloak via Docker.
│   └── minio.yml       # Playbook pour déployer MinIO.
├── roles/
│   ├── java/           # Rôle pour l'installation de Java.
│   ├── mysql/          # Rôle pour l'installation et la configuration de MySQL.
│   ├── rundeck/        # Rôle pour l'installation et la configuration de Rundeck.
│   ├── nginx/          # Rôle pour l'installation et la configuration de Nginx.
│   ├── keycloak/       # Rôle pour le déploiement de Keycloak.
│   └── minio/          # Rôle pour le déploiement de MinIO.
└── README.md           # Ce fichier de documentation.
```

## Configuration

### 1. Configurer l'Inventaire

Modifiez le fichier `ansible/inventory/hosts` pour y ajouter les adresses IP ou les noms de domaine de vos serveurs cibles.

**Exemple :**

```ini
# Décommentez et modifiez cette section pour définir vos serveurs.
# [servers]
# serveur1 ansible_host=192.168.1.10
# serveur2 ansible_host=192.168.1.11

# Vous pouvez également définir un groupe spécifique pour votre stack.
[stack_rundeck]
rundeck-master ansible_host=10.0.0.5 ansible_user=ubuntu
```

### 2. Personnaliser les Variables (Optionnel)

Chaque rôle possède un fichier `defaults/main.yml` (`ansible/roles/<nom_du_role>/defaults/main.yml`) où vous pouvez surcharger les variables par défaut.

**IMPORTANT :** Pour un environnement de production, il est crucial de modifier les mots de passe par défaut.

*   **MySQL :** `ansible/roles/mysql/defaults/main.yml` (variables `db_password`).
*   **Rundeck :** `ansible/roles/rundeck/defaults/main.yml` (variables `rundeck_db_password`).
*   **Keycloak :** `ansible/roles/keycloak/defaults/main.yml` (variables `keycloak_admin_password`).
*   **MinIO :** `ansible/roles/minio/defaults/main.yml` (variables `minio_root_user`, `minio_root_password`).

## Utilisation : Exécution des Playbooks

Toutes les commandes doivent être exécutées depuis le répertoire `ansible/`. La commande de base est `ansible-playbook -i inventory/hosts <chemin_vers_le_playbook>`.

### Déployer la Stack Complète

Pour déployer Java, MySQL, Rundeck et Keycloak en une seule fois :

```bash
ansible-playbook -i inventory/hosts playbooks/site.yml
```

### Déployer un Composant Spécifique

Vous pouvez utiliser les playbooks individuels pour ne déployer qu'une partie de la stack.

*   **Installer uniquement Java :**
    ```bash
    ansible-playbook -i inventory/hosts playbooks/java.yml
    ```

*   **Installer uniquement MySQL :**
    ```bash
    ansible-playbook -i inventory/hosts playbooks/mysql.yml
    ```

*   **Installer Rundeck et ses dépendances (Java, MySQL, Nginx) :**
    ```bash
    ansible-playbook -i inventory/hosts playbooks/rundeck.yml
    ```

*   **Installer et configurer Nginx uniquement :**
    ```bash
    ansible-playbook -i inventory/hosts playbooks/nginx.yml
    ```

*   **Déployer uniquement Keycloak :**
    ```bash
    ansible-playbook -i inventory/hosts playbooks/keycloak.yml
    ```

*   **Déployer uniquement MinIO :**
    ```bash
    ansible-playbook -i inventory/hosts playbooks/minio.yml
    ```

### Utiliser les Tags pour une Exécution Granulaire

Vous pouvez également utiliser des tags pour exécuter uniquement certaines parties d'un playbook. Par exemple, pour n'exécuter que les tâches liées à Rundeck ou MinIO du playbook principal :

```bash
ansible-playbook -i inventory/hosts playbooks/site.yml --tags "rundeck"
ansible-playbook -i inventory/hosts playbooks/site.yml --tags "minio"
```