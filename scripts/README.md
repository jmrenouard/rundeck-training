# Scripts d'Installation et de Maintenance pour Rundeck

Ce répertoire contient une collection de scripts Bash conçus pour l'installation, la configuration, la sauvegarde et la restauration d'une stack Rundeck complète sur un système **Ubuntu**.

## Philosophie des Scripts

Ces scripts offrent une alternative **transparente et directe** à l'automatisation avec Ansible. Ils sont idéaux pour :
-   Des déploiements sur des serveurs "bare-metal".
-   Des environnements où Ansible n'est pas disponible ou souhaité.
-   Comprendre en détail chaque étape de l'installation.

Tous les scripts suivent des principes de robustesse :
-   **`set -e` et `set -o pipefail`** : Le script s'arrête immédiatement si une commande échoue.
-   **Journalisation** : Toutes les actions sont journalisées dans `/var/log/` pour un débogage facile.
-   **Sorties Colorées** : Des fonctions `info`, `success`, `warn`, `error` sont utilisées pour une lisibilité accrue lors de l'exécution.
-   **Vérification des Droits** : La plupart des scripts vérifient qu'ils sont exécutés avec les privilèges `root`.

---

## Scripts d'Installation

Ces scripts installent et configurent les services de la stack.

### 1. Script Orchestrateur : `install_ubuntu.sh`

C'est le **point d'entrée principal**. Il exécute les autres scripts d'installation dans le bon ordre.

**Utilisation :**
```bash
# Assurez-vous que tous les scripts sont présents et exécutables
sudo ./install_ubuntu.sh
```

### 2. Scripts Composants

-   **`install_java.sh`**: Installe OpenJDK 11, une dépendance critique pour Rundeck.
-   **`install_mysql.sh`**: Installe le serveur MySQL, crée la base de données `rundeck` et l'utilisateur `rundeckuser`.
    -   **⚠️ SÉCURITÉ :** Ce script utilise des identifiants par défaut. Pour un usage en production, modifiez le script pour utiliser des mots de passe forts ou, mieux encore, exécutez `mysql_secure_installation` après coup.
-   **`install_rundeck.sh`**: Installe Rundeck, le configure pour utiliser la base de données MySQL et le rend accessible sur le réseau.
-   **`install_minio.sh`**: Installe le serveur de stockage objet MinIO et le configure comme un service `systemd`.
    -   **⚠️ SÉCURITÉ :** Les identifiants root de MinIO sont définis dans `/etc/minio/minio.env`. Modifiez ce fichier après l'installation pour sécuriser votre instance.

---

## Scripts d'Opérations

Ces scripts sont essentiels pour la maintenance et la reprise après sinistre.

### Sauvegarde : `backup_rundeck.sh`

Ce script crée une sauvegarde **complète et cohérente** de l'instance Rundeck.

**Processus :**
1.  Arrête le service `rundeckd` pour garantir qu'aucune donnée n'est en cours d'écriture.
2.  Sauvegarde la base de données MySQL avec `mysqldump`.
3.  Crée une archive `.tar.gz` unique contenant :
    -   Le dump SQL.
    -   Les définitions de projets (`/var/lib/rundeck/projects`).
    -   Les clés de sécurité (`/var/lib/rundeck/keystore`).
    -   Les logs d'exécution (`/var/lib/rundeck/logs`).
    -   Les fichiers de configuration (`/etc/rundeck`).
4.  Redémarre le service `rundeckd`.

**Utilisation :**
```bash
sudo ./backup_rundeck.sh
```
La sauvegarde est stockée dans `/var/backups/rundeck/` avec un nom horodaté.

### Restauration : `restore_rundeck.sh`

Ce script restaure une instance Rundeck à partir d'une archive de sauvegarde.

**⚠️ ATTENTION :** Ce script est **destructif**. Il effacera les données actuelles de Rundeck pour les remplacer par celles de la sauvegarde.

**Processus :**
1.  Prend le chemin d'un fichier de sauvegarde en argument.
2.  Arrête le service `rundeckd`.
3.  Supprime les anciens répertoires de données et de configuration.
4.  Restaure les fichiers et les répertoires depuis l'archive.
5.  Restaure la base de données MySQL.
6.  Rétablit les permissions des fichiers pour l'utilisateur `rundeck`.
7.  Redémarre le service `rundeckd`.

**Utilisation :**
```bash
sudo ./restore_rundeck.sh /var/backups/rundeck/rundeck_backup_YYYYMMDD_HHMMSS.tar.gz
```

## Bonnes Pratiques en Production

-   **Automatisez les Sauvegardes** : Utilisez `cron` pour exécuter `backup_rundeck.sh` automatiquement.
    ```bash
    # /etc/crontab
    # Exécute une sauvegarde tous les jours à 2h du matin
    0 2 * * * root /path/to/scripts/backup_rundeck.sh
    ```
-   **Externalisez les Sauvegardes** : Ne laissez pas les sauvegardes sur le même serveur que Rundeck. Utilisez un job Rundeck (comme le template `transfert-s3.yml`) ou un autre script pour copier les archives de sauvegarde vers un stockage externe (MinIO, S3, etc.).
-   **Sécurisez MySQL et MinIO** : Changez tous les mots de passe par défaut immédiatement après l'installation.