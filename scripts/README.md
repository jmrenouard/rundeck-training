# Documentation des Scripts

Ce répertoire contient une collection de scripts Bash conçus pour automatiser l'installation, la configuration, la sauvegarde et la restauration d'une stack Rundeck complète sur un système Ubuntu.

## Organisation des Scripts

Les scripts sont organisés en deux catégories principales :

- **Scripts d'Installation** : Pour déployer les composants de la stack.
- **Scripts de Sauvegarde et Restauration** : Pour gérer le cycle de vie des données de Rundeck.

---

## Scripts d'Installation

Ces scripts installent et configurent les différents services nécessaires au fonctionnement de Rundeck.

### Script Principal: `install_ubuntu.sh`

C'est le script principal à exécuter. Il orchestre l'exécution des autres scripts d'installation dans le bon ordre pour installer la stack complète.

**Fonctionnalités :**
- Vérifie les droits `root`.
- Exécute séquentiellement `install_java.sh`, `install_mysql.sh`, et `install_rundeck.sh`.
- Centralise les logs de l'ensemble du processus d'installation dans `/var/log/rundeck_install_*.log`.
- Affiche un résumé à la fin avec l'URL d'accès à Rundeck.

**Utilisation :**
Assurez-vous que tous les scripts sont dans le même répertoire, puis exécutez :
```bash
sudo ./install_ubuntu.sh
```

### Script d'installation de Java: `install_java.sh`

Le script `install_java.sh` installe OpenJDK 11, qui est une dépendance requise pour Rundeck.

**Fonctionnalités :**
- Vérifie si Java 11 est déjà installé.
- Installe `openjdk-11-jdk`.
- Configure la variable d'environnement `JAVA_HOME` dans `/etc/environment` pour l'ensemble du système.

### Script d'installation de MySQL: `install_mysql.sh`

Le script `install_mysql.sh` installe le serveur de base de données MySQL et le prépare pour Rundeck.

**Fonctionnalités :**
- Installe `mysql-server`.
- Démarre et active le service MySQL.
- Crée une base de données (`rundeck`) et un utilisateur (`rundeckuser`) pour que Rundeck puisse s'y connecter.
- **Note :** Les identifiants sont codés en dur dans le script. Pour un usage en production, il est fortement recommandé de les modifier et de sécuriser l'installation MySQL.

### Script d'installation de Rundeck: `install_rundeck.sh`

Le script `install_rundeck.sh` installe l'application Rundeck elle-même.

**Fonctionnalités :**
- Ajoute le référentiel officiel de Rundeck.
- Installe le paquet `rundeck`.
- Configure Rundeck pour se connecter à la base de données MySQL créée précédemment.
- Configure l'URL du serveur et l'adresse d'écoute pour rendre Rundeck accessible sur le réseau.
- Démarre et active le service `rundeckd`.
- Attend que l'application soit pleinement démarrée et teste l'accès.

### Script d'installation de MinIO: `install_minio.sh`

Le script `install_minio.sh` installe et configure un serveur de stockage d'objets MinIO.

**Fonctionnalités :**
- Crée un utilisateur (`minio-user`) et un groupe dédiés pour le service.
- Met en place les répertoires de configuration (`/etc/minio`) et de données (`/var/minio`).
- Télécharge le binaire officiel de MinIO.
- Configure un service `systemd` (`minio.service`) pour une gestion propre du serveur.
- Démarre et active le service MinIO.
- **Note :** Le script génère un fichier d'environnement (`/etc/minio/minio.env`) avec des identifiants par défaut. Il est crucial de les modifier pour un environnement de production.

**Utilisation :**
```bash
sudo ./install_minio.sh
```

---

## Scripts de Sauvegarde et Restauration

Ces scripts sont dédiés à la gestion des sauvegardes et des restaurations de votre instance Rundeck pour assurer la sécurité de vos données.

### Script de Sauvegarde: `backup_rundeck.sh`

Ce script permet de créer une sauvegarde complète de l'instance Rundeck.

**Fonctionnalités :**
- Arrête le service `rundeckd` pour assurer la cohérence des données.
- Sauvegarde la base de données MySQL `rundeck` via `mysqldump`.
- Crée une archive `.tar.gz` contenant :
  - Le dump de la base de données.
  - Les logs (`/var/lib/rundeck/logs`).
  - Les keystores (`/var/lib/rundeck/keystore`).
  - Les définitions de projets (`/var/lib/rundeck/projects`).
  - Les fichiers de configuration (`/etc/rundeck`).
- Redémarre le service `rundeckd` une fois la sauvegarde terminée.
- Stocke la sauvegarde dans `/var/backups/rundeck/` avec un horodatage.

**Utilisation :**
```bash
sudo ./backup_rundeck.sh
```

### Script de Restauration: `restore_rundeck.sh`

Ce script permet de restaurer Rundeck à partir d'un fichier de sauvegarde créé par `backup_rundeck.sh`.

**Fonctionnalités :**
- Prend le chemin vers un fichier de sauvegarde en argument.
- Arrête le service `rundeckd`.
- Restaure la base de données MySQL à partir du dump SQL contenu dans l'archive.
- Supprime les anciennes données et restaure les fichiers et répertoires de Rundeck.
- Rétablit les permissions (`chown`) pour l'utilisateur `rundeck`.
- Redémarre le service `rundeckd`.

**Utilisation :**
```bash
sudo ./restore_rundeck.sh /var/backups/rundeck/rundeck_backup_YYYYMMDD_HHMMSS.tar.gz
```